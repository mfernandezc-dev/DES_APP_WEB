param([long]$PedidoId=1, [long]$ProductoId=1, [switch]$DesdeRetry)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$runtime = Join-Path $root '.runtime'
$evidence = Join-Path $root 'evidencias'
$control = Join-Path $PSScriptRoot 'Servicios-Lab.ps1'
function Assert($Condition, $Message) { if (!$Condition) { throw "ASSERT: $Message" }; Write-Output "PASS: $Message" }
function Get-Json($Url, $Headers=@{}) { Invoke-RestMethod -Uri $Url -Headers $Headers -TimeoutSec 45 }
function Save($Folder, $Name, $Value) { $Value | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $evidence "$Folder/$Name.json") -Encoding UTF8 }
function Wait-Ready($Port) {
    $deadline = [DateTime]::UtcNow.AddSeconds(100)
    do {
        $path = if ($Port -eq 8082) {'/api/categorias'} else {'/actuator/info'}
        try { Invoke-WebRequest "http://localhost:$Port$path" -UseBasicParsing -TimeoutSec 3 | Out-Null; return } catch { Start-Sleep -Milliseconds 1000 }
    } while ([DateTime]::UtcNow -lt $deadline)
    throw "Servicio $Port no listo. Revisar .runtime."
}
function Wait-Data($Url, $Predicate) {
    $deadline = [DateTime]::UtcNow.AddSeconds(150)
    do {
        try { $data = Get-Json $Url; if (& $Predicate $data) { return $data } } catch {}
        Start-Sleep -Seconds 2
    } while ([DateTime]::UtcNow -lt $deadline)
    throw "No se estabilizo descubrimiento/datos reales en $Url"
}
function Restart($Service, $Port, [bool]$Lab=$true) {
    & $control -Accion Reiniciar -Servicio $Service -Simulacion:$Lab
    Wait-Ready $Port
}
function Read-LogLines($Service) {
    $path=Join-Path $runtime "$Service.stdout.log"
    $stream=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    $reader=New-Object IO.StreamReader($stream)
    try { while (($line=$reader.ReadLine()) -ne $null) { [string]::Concat('', $line) } }
    finally { $reader.Dispose(); $stream.Dispose() }
}
function Snapshot-Log($Service) { @(Read-LogLines $Service).Count }
# Strings puros sin metadatos PSProvider y acceso compartido con el proceso Java.
function Log-After($Service, $Start) { Read-LogLines $Service | Select-Object -Skip $Start }
function Circuit($Port, $Name) { (Get-Json "http://localhost:$Port/actuator/circuitbreakers").circuitBreakers.$Name }

Add-Type -AssemblyName System.Net.Http
Add-Type -ReferencedAssemblies System.Net.Http -TypeDefinition @'
using System;
using System.Linq;
using System.Diagnostics;
using System.Net.Http;
using System.Threading.Tasks;
public class LabHttpResult {
    public int Index; public int Status; public long Milliseconds; public string Body;
}
public static class LabHttp {
    public static async Task<LabHttpResult[]> Run(string url, string header, string value, int count) {
        using (var handler = new HttpClientHandler { MaxConnectionsPerServer = 16 })
        using (var client = new HttpClient(handler)) {
            client.Timeout = TimeSpan.FromSeconds(45);
            return await Task.WhenAll(Enumerable.Range(0,count).Select(async i => {
                var timer = Stopwatch.StartNew();
                using (var request = new HttpRequestMessage(HttpMethod.Get,url)) {
                    if (header != null) request.Headers.Add(header,value);
                    using (var response = await client.SendAsync(request)) {
                        string body = await response.Content.ReadAsStringAsync();
                        return new LabHttpResult { Index=i, Status=(int)response.StatusCode, Milliseconds=timer.ElapsedMilliseconds, Body=body };
                    }
                }
            }));
        }
    }
}
'@

# Nunca se realizan POST/PUT/DELETE: los datos existentes se mantienen intactos.
foreach ($port in 8082,8083,8084,8085) { Wait-Ready $port }
$direct = Wait-Data "http://localhost:8085/api/pedidos/$PedidoId" {param($p) $p.id -eq $PedidoId -and $p.producto.precio -ne $null}
$via = Wait-Data "http://localhost:8084/api/clientes/pedidos/$PedidoId" {param($p) $p.id -eq $PedidoId -and $p.producto.precio -ne $null}
Assert ($direct.id -eq $PedidoId -and $via.id -eq $PedidoId -and $via.producto.nombre -eq $direct.producto.nombre) 'Comunicacion directa y Feign con datos reales'
Save 'circuit-breaker' 'antes' @{Timestamp=(Get-Date -Format o);Directa=$direct;Feign=$via}

# Fase 2: caida real del proceso identificado, OPEN y recuperacion.
if (!$DesdeRetry) {
Restart 'cliente-service' 8084
try {
    & $control -Accion Detener -Servicio 'pedido-service'
    $failures = 1..4 | ForEach-Object { Get-Json "http://localhost:8084/api/clientes/pedidos/$PedidoId" }
    $state = Circuit 8084 'pedidoService'
    Save 'circuit-breaker' 'pedido-detenido' @{Responses=$failures;Circuit=$state}
    Assert (@($failures | Where-Object {$_.disponible -eq $false}).Count -eq 4) 'Cliente usa fallback con Pedido detenido'
    Assert ($state.state -eq 'OPEN') 'Circuito pedidoService OPEN'
} finally { Restart 'pedido-service' 8085 }
Start-Sleep -Seconds 11
$null = Wait-Data "http://localhost:8084/api/clientes/pedidos/$PedidoId" {param($p) $p.id -eq $PedidoId -and $p.producto.precio -ne $null}
$recovery = 1..10 | ForEach-Object { Get-Json "http://localhost:8084/api/clientes/pedidos/$PedidoId" }
Assert (@($recovery | Where-Object {$_.id -eq $PedidoId}).Count -eq 10) 'Feign recuperado tras reiniciar Pedido'
Save 'circuit-breaker' 'recuperacion' @{Responses=$recovery;Circuit=(Circuit 8084 'pedidoService')}
}

# Fase 3: una solicitud logica, tres invocaciones HTTP (no tres solicitudes del usuario).
Restart 'producto-service' 8083
try {
    & $control -Accion Detener -Servicio 'categoria-service'
    $start = Snapshot-Log 'producto-service'
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $response = Get-Json "http://localhost:8083/api/productos/$ProductoId"
    $elapsed = $timer.ElapsedMilliseconds
    $lines = @(Log-After 'producto-service' $start)
    $attempts = @($lines | Where-Object {$_ -match 'Llamando a categoria-service'}).Count
    Save 'retry' 'categoria-no-disponible' @{Response=$response;Milliseconds=$elapsed;Attempts=$attempts;Console=$lines}
    Assert ($attempts -eq 3) 'Retry categoria: tres intentos HTTP comprobados en consola'
    Assert ($elapsed -ge 4000 -and $response.categoria.estado -eq 'NO DISPONIBLE') 'Retry espera y luego fallback'
} finally { Restart 'categoria-service' 8082 }
Restart 'producto-service' 8083
$response = Wait-Data "http://localhost:8083/api/productos/$ProductoId" {param($p) $p.categoria.estado -eq 'ACTIVO'}
Assert ($response.categoria.estado -ne 'NO DISPONIBLE') 'Categoria recuperada'
Save 'retry' 'categoria-disponible' $response

# Fase 4: concurrencia HTTP real y demora controlada de diez segundos.
$start = Snapshot-Log 'categoria-service'
$rows = [LabHttp]::Run("http://localhost:8083/api/productos/$ProductoId", 'X-Lab-Categoria-Delay-Ms','10000',4).GetAwaiter().GetResult()
Assert (@($rows | Where-Object {$_.Status -eq 200}).Count -eq 4) 'Cuatro respuestas HTTP 200 en Bulkhead categoria'
$real = @($rows | Where-Object {($_.Body | ConvertFrom-Json).categoria.estado -ne 'NO DISPONIBLE'})
$fallback = @($rows | Where-Object {($_.Body | ConvertFrom-Json).categoria.estado -eq 'NO DISPONIBLE'})
Save 'bulkhead' 'categoria-concurrente' @{Responses=$rows;Console=@(Log-After 'categoria-service' $start);Bulkheads=(Get-Json 'http://localhost:8083/actuator/bulkheads')}
Assert ($real.Count -eq 2 -and $fallback.Count -eq 2) 'Bulkhead categoria admite dos y rechaza dos'
Assert (@($real | Where-Object {$_.Milliseconds -ge 10000}).Count -eq 2) 'Dos respuestas reales con demora de diez segundos'
Assert (@($fallback | Where-Object {$_.Milliseconds -lt 5000}).Count -eq 2) 'Rechazos rapidos sin reintentar Bulkhead lleno'

# Fase 5: cliente tarda cinco segundos, timeout de lectura de dos segundos.
$start = Snapshot-Log 'pedido-service'
$clientStart = Snapshot-Log 'cliente-service'
$timer = [Diagnostics.Stopwatch]::StartNew()
$response = Get-Json 'http://localhost:8085/api/pedidos?detallado=true' @{'X-Lab-Cliente-Delay-Ms'='5000'}
$lines = @(Log-After 'pedido-service' $start)
$attempts = @($lines | Where-Object {$_ -match 'Intento HTTP hacia cliente-service'}).Count
Save 'actividad-final' 'cliente-retry' @{Response=$response;Milliseconds=$timer.ElapsedMilliseconds;Attempts=$attempts;Console=$lines;ClienteConsole=@(Log-After 'cliente-service' $clientStart)}
Assert ($attempts -eq 3) 'Cliente Retry: tres intentos por timeout'
Assert (@($response | Where-Object {$_.cliente.nombre -eq 'Cliente temporalmente no disponible'}).Count -ge 1) 'Cliente fallback tras agotar Retry'
$normal = Get-Json 'http://localhost:8085/api/pedidos?detallado=true'
Assert ($normal[0].cliente.nombre -ne 'Cliente temporalmente no disponible') 'Cliente recuperado sin cabecera de demora'

$start = Snapshot-Log 'producto-service'
$rows = [LabHttp]::Run('http://localhost:8085/api/pedidos?detallado=true', 'X-Lab-Producto-Delay-Ms','10000',4).GetAwaiter().GetResult()
Assert (@($rows | Where-Object {$_.Status -eq 200}).Count -eq 4) 'Cuatro respuestas HTTP 200 en Bulkhead producto'
$real = @($rows | Where-Object {($_.Body | ConvertFrom-Json)[0].producto.precio -ne $null})
$fallback = @($rows | Where-Object {($_.Body | ConvertFrom-Json)[0].producto.precio -eq $null})
Save 'actividad-final' 'producto-bulkhead' @{Responses=$rows;Console=@(Log-After 'producto-service' $start);Bulkheads=(Get-Json 'http://localhost:8085/actuator/bulkheads')}
Assert ($real.Count -eq 2 -and $fallback.Count -eq 2) 'Bulkhead producto admite dos y rechaza dos'
Assert (@($real | Where-Object {$_.Milliseconds -ge 10000}).Count -eq 2) 'Producto demora diez segundos en dos respuestas reales'

$legacy = Get-Json 'http://localhost:8085/api/pedidos'
$normal = Get-Json "http://localhost:8085/api/pedidos/$PedidoId"
Save 'actividad-final' 'recuperacion' @{Legacy=$legacy;Pedido=$normal}
Assert ($legacy[0].idPedido -eq $PedidoId -and $normal.producto.precio -eq $direct.producto.precio) 'Contrato original y datos preservados'
Write-Output 'Todas las aserciones del recorrido finalizaron correctamente.'
