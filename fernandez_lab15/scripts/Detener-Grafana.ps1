[CmdletBinding(SupportsShouldProcess=$true)]
param()
. (Join-Path $PSScriptRoot 'Entorno-Grafana.ps1')
$recordFile=Join-Path $GrafRuntime 'proceso.json'
if(!(Test-Path $recordFile)) { throw 'No existe registro de Grafana propio.' }
$record=Get-Content $recordFile -Raw | ConvertFrom-Json
if(!(Get-Process -Id $record.PID -ErrorAction SilentlyContinue)) { Write-Host 'Grafana propio ya esta detenido.'; return }
if(!(Test-GrafanaIdentity $record)) { throw 'Identidad no coincide; no se detiene ningun proceso.' }
if($PSCmdlet.ShouldProcess("Grafana Lab 15 PID $($record.PID)",'Detener exclusivamente el proceso registrado')) {
    Stop-Process -Id $record.PID
    Write-Host 'Grafana propio detenido. SQLite/datos conservados; Java, MariaDB y Prometheus no se detienen.'
}
