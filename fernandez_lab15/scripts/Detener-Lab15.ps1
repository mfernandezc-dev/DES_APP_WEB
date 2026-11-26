# Nunca mata por puerto o por nombre generico java.exe.
[CmdletBinding(SupportsShouldProcess=$true)]
param([ValidateSet('02','03')][string]$Paso = '03')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
$registry = Join-Path $Lab15Root ".runtime\paso$Paso\procesos.json"
if (!(Test-Path $registry)) { throw 'No existe registro de procesos propios.' }
$records = Get-Content $registry -Raw | ConvertFrom-Json
[array]::Reverse($records)
foreach ($record in $records) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($record.PID)"
    if (!$process) { Write-Host "$($record.Service): ya detenido"; continue }
    $actual = Get-Process -Id $record.PID -ErrorAction Stop
    if ($process.ExecutablePath -ne $record.Java -or
        $process.CommandLine -notlike "*@../.runtime/paso$Paso/$($record.Service).args*" -or
        $actual.StartTime.ToUniversalTime().ToString('o') -ne $record.StartTimeUtc -or
        $record.ArgsFile -ne (Join-Path $Lab15Root ".runtime\paso$Paso\$($record.Service).args")) {
        Write-Warning "PID $($record.PID): identidad distinta. No se detiene."
        continue
    }
    if ($PSCmdlet.ShouldProcess("$($record.Service), PID $($record.PID)", 'Detener proceso propio de Lab 15')) {
        Stop-Process -Id $record.PID
        Write-Host "$($record.Service): detenido PID $($record.PID)"
    }
}
