$ErrorActionPreference='Stop'
$GrafRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if((Split-Path $GrafRoot -Leaf) -ne 'fernandez_lab15') { throw 'Raiz no autorizada.' }
$GrafRuntime=Join-Path $GrafRoot '.runtime\grafana'
$GrafStep=Join-Path $GrafRoot '.runtime\paso05'
$GrafEvidence=Join-Path $GrafRoot 'evidencias\04-grafana'
$GrafPrivate=Join-Path $GrafRuntime 'private'
function Get-GrafanaCredential {
    $path=Join-Path $GrafPrivate 'admin.clixml'
    if(!(Test-Path $path)) { throw 'No hay credencial local DPAPI. Preparar acceso antes de autenticar.' }
    return (Import-Clixml -LiteralPath $path)
}
function Test-GrafanaIdentity($Record) {
    # Solo lecturas: evitar que -WhatIf omita operaciones internas de Get-FileHash
    # o la carga automatica de CimCmdlets en Windows PowerShell 5.1.
    $WhatIfPreference=$false
    $process=Get-CimInstance Win32_Process -Filter "ProcessId=$($Record.PID)"
    if(!$process) { return $false }
    $actual=Get-Process -Id $Record.PID
    if($process.ExecutablePath -ne $Record.Executable -or $actual.StartTime.ToUniversalTime().ToString('o') -ne $Record.StartTimeUtc -or $Record.Runtime -ne $GrafRuntime) { return $false }
    foreach($argument in $Record.Arguments) { if($process.CommandLine.IndexOf($argument,[StringComparison]::OrdinalIgnoreCase) -lt 0) { return $false } }
    $stream=[IO.File]::OpenRead($Record.Executable)
    $algorithm=[Security.Cryptography.SHA256]::Create()
    try { $hash=[BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','') } finally { $algorithm.Dispose();$stream.Dispose() }
    return $hash -eq $Record.ExecutableSHA256
}
