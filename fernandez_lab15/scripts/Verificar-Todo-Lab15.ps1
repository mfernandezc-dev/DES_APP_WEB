# Solo lecturas: comprobacion general repetible, sin instalar/iniciar/reiniciar.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Entorno-Grafana.ps1')
$runtime=Join-Path $Lab15Root '.runtime\paso06'
$null=New-Item -ItemType Directory $runtime -Force
$listeners=@(Get-NetTCPConnection -State Listen)
$all=@(Get-CimInstance Win32_Process)
$registry=@((Get-Content (Join-Path $Lab15Root '.runtime\paso03\procesos.json') -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
$checks=@()
foreach($r in $registry) {
    $p=$all | Where-Object ProcessId -eq $r.PID
    $actual=Get-Process -Id $r.PID
    $own=@($listeners | Where-Object OwningProcess -eq $r.PID)
    $same=$p -and $p.ExecutablePath -eq $r.Java -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $r.StartTimeUtc -and $p.CommandLine -like "*@../.runtime/paso03/$($r.Service).args*"
    $instances=@($all | Where-Object { $_.Name -in @('java.exe','javaw.exe') -and $_.CommandLine -like "*@../.runtime/paso03/$($r.Service).args*" }).Count
    $checks += [pscustomobject]@{Name=$r.Service;PID=$r.PID;Port=$r.Port;Identity=[bool]$same;Instances=$instances;LocalhostOnly=($own.Count -eq 1 -and $own[0].LocalAddress -eq '127.0.0.1' -and $own[0].LocalPort -eq $r.Port);ArtifactUnchanged=((Get-FileHash $r.Jar -Algorithm SHA256).Hash -eq $r.JarSHA256)}
}
foreach($component in @('prometheus','grafana')) {
    $r=Get-Content (Join-Path $Lab15Root ".runtime\$component\proceso.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $p=$all | Where-Object ProcessId -eq $r.PID
    $actual=Get-Process -Id $r.PID
    $same=$p -and $p.ExecutablePath -eq $r.Executable -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $r.StartTimeUtc
    foreach($a in $r.Arguments) { if($p.CommandLine.IndexOf($a,[StringComparison]::OrdinalIgnoreCase) -lt 0) { $same=$false } }
    $own=@($listeners | Where-Object OwningProcess -eq $r.PID)
    $checks += [pscustomobject]@{Name=$component;PID=$r.PID;Port=$r.Port;Identity=[bool]$same;Instances=@($all | Where-Object Name -eq ([IO.Path]::GetFileName($r.Executable))).Count;LocalhostOnly=($own.Count -eq 1 -and $own[0].LocalAddress -eq '127.0.0.1' -and $own[0].LocalPort -eq $r.Port);ArtifactUnchanged=((Get-FileHash $r.Executable -Algorithm SHA256).Hash -eq $r.ExecutableSHA256)}
}
$checks | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $runtime 'procesos-verificados.json') -Encoding UTF8
if($checks.Count -ne 9 -or @($checks | Where-Object { !$_.Identity -or !$_.LocalhostOnly -or !$_.ArtifactUnchanged -or $_.Instances -ne 1 }).Count) { throw 'Procesos no coinciden con identidades, artefactos o listeners locales esperados.' }
& 'C:\Program Files\nodejs\node.exe' (Join-Path $PSScriptRoot 'Verificar-Todo-Lab15.mjs') --paso=06
if($LASTEXITCODE -ne 0) { throw 'Fallo una comprobacion funcional/de observabilidad. Revisar PRUEBAS-FINALES.json.' }
