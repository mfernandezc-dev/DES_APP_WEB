[CmdletBinding(SupportsShouldProcess=$true)]
param()
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Prometheus.ps1')
$path=Join-Path $PromRuntime 'proceso.json'
if(!(Test-Path $path)) { throw 'No existe registro de Prometheus propio.' }
$record=Get-Content $path -Raw | ConvertFrom-Json
$process=Get-CimInstance Win32_Process -Filter "ProcessId=$($record.PID)"
if(!$process) { Write-Host 'Prometheus propio ya esta detenido.'; return }
$actual=Get-Process -Id $record.PID
$matches=$process.ExecutablePath -eq $PromExecutable -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $record.StartTimeUtc -and $record.DataPath -eq (Join-Path $PromRuntime 'data')
foreach($argument in $record.Arguments) { if($process.CommandLine.IndexOf($argument,[StringComparison]::OrdinalIgnoreCase) -lt 0) { $matches=$false } }
if(!$matches) { throw 'La identidad no coincide; no se detiene ningun proceso.' }
if($PSCmdlet.ShouldProcess("Prometheus Lab 15, PID $($record.PID)",'Detener exclusivamente el proceso registrado')) {
    Stop-Process -Id $record.PID
    Write-Host "Prometheus propio detenido: PID $($record.PID). No se eliminan TSDB/WAL ni se detienen Java/MariaDB."
}
