# Idempotente: reutiliza servicios propios saludables; nunca instala herramientas.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Entorno-Grafana.ps1')
& (Join-Path $PSScriptRoot 'Iniciar-Lab15.ps1') -Paso 03 -ReutilizarActivos
$promRecord=Join-Path $Lab15Root '.runtime\prometheus\proceso.json'
$listeners=@(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq 9090)
if($listeners.Count) {
    if(!(Test-Path $promRecord)) { throw 'Prometheus ocupa 9090 sin registro propio; no se modifica.' }
    $r=Get-Content $promRecord -Raw | ConvertFrom-Json
    $p=Get-CimInstance Win32_Process -Filter "ProcessId=$($r.PID)"
    $actual=Get-Process -Id $r.PID
    if(!$p -or $p.ExecutablePath -ne $r.Executable -or $actual.StartTime.ToUniversalTime().ToString('o') -ne $r.StartTimeUtc -or $listeners.Count -ne 1 -or $listeners[0].OwningProcess -ne $r.PID -or $listeners[0].LocalAddress -ne '127.0.0.1') { throw 'Prometheus no coincide con la identidad local registrada.' }
    foreach($a in $r.Arguments) { if($p.CommandLine.IndexOf($a,[StringComparison]::OrdinalIgnoreCase) -lt 0) { throw 'Argumentos Prometheus distintos.' } }
    $null=Invoke-WebRequest 'http://localhost:9090/-/ready' -UseBasicParsing -TimeoutSec 15
    Write-Host "Prometheus reutilizado PID=$($r.PID)."
} else { & (Join-Path $PSScriptRoot 'Iniciar-Prometheus.ps1') }
& (Join-Path $PSScriptRoot 'Iniciar-Grafana.ps1')
if(!(Test-Path (Join-Path $Lab15Root '.runtime\paso05\checkpoint-auth.json'))) {
    & 'C:\Program Files\nodejs\node.exe' (Join-Path $PSScriptRoot 'Inicializar-Acceso-Grafana.mjs')
    if($LASTEXITCODE -ne 0) { throw 'Completar acceso administrativo local antes de continuar.' }
}
Write-Host 'Conjunto disponible. MariaDB solo comprobada, nunca iniciada ni detenida automaticamente.'
