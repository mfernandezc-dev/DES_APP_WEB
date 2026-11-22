param([switch]$SoloRecuperacionProducto)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$control=Join-Path $PSScriptRoot 'Servicios-Lab.ps1'
$results=@()
$cases=@(
    @{Service='categoria-service';Port=8083;Circuit='categoriaService';Url='http://localhost:8083/api/productos/1';File='categoria';Field='categoria'},
    @{Service='producto-service';Port=8085;Circuit='productoService';Url='http://localhost:8085/api/pedidos/1';File='producto';Field='producto'}
)
if($SoloRecuperacionProducto){$cases=@($cases | Where-Object File -eq 'producto')}
foreach($case in $cases) {
    if(!$SoloRecuperacionProducto){
    try {
        & $control -Accion Detener -Servicio $case.Service
        $responses=@(1..4 | ForEach-Object {Invoke-RestMethod $case.Url -TimeoutSec 45})
        $state=(Invoke-RestMethod "http://localhost:$($case.Port)/actuator/circuitbreakers").circuitBreakers.($case.Circuit)
        if($state.state -ne 'OPEN'){throw "$($case.Circuit) no llego a OPEN"}
        $failure=@{Responses=$responses;Circuit=$state}
        $failure | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $root "evidencias/circuit-breaker/$($case.File)-open.json") -Encoding UTF8
        Write-Output "PASS: $($case.Circuit) OPEN con servicio detenido"
    } finally { & $control -Accion Reiniciar -Servicio $case.Service }
    }
    $deadline=[DateTime]::UtcNow.AddSeconds(150)
    $real=$false
    $successes=0
    $closed=$false
    do {
        try {
            $data=Invoke-RestMethod $case.Url -TimeoutSec 45
            $real=if($case.Field -eq 'categoria'){$data.categoria.estado -eq 'ACTIVO'}else{$data.producto.precio -eq 2500}
            $state=(Invoke-RestMethod "http://localhost:$($case.Port)/actuator/circuitbreakers").circuitBreakers.($case.Circuit)
            $closed=$state.state -eq 'CLOSED'
        } catch { $real=$false }
        if($real){$successes++}else{$successes=0}
        if(!$real -or !$closed){Start-Sleep -Seconds 2}
    } while(($successes -lt 10 -or !$closed) -and [DateTime]::UtcNow -lt $deadline)
    if($successes -lt 10 -or !$closed){throw "Sin recuperacion estable de $($case.Circuit)"}
    @{Response=$data;Circuit=$state;Profiles='dev'} | ConvertTo-Json -Depth 10 |
        Set-Content (Join-Path $root "evidencias/circuit-breaker/$($case.File)-recuperacion.json") -Encoding UTF8
    Write-Output "PASS: $($case.Circuit) recuperado y CLOSED"
}
