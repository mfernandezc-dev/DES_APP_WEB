$ErrorActionPreference='Stop'
$PromLabRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$PromRuntime=Join-Path $PromLabRoot '.runtime\prometheus'
$PromEvidence=Join-Path $PromLabRoot 'evidencias\03-prometheus'
$PromConfig=Join-Path $PromLabRoot 'observabilidad\prometheus\prometheus.yml'
$receipt=Join-Path $PromRuntime 'instalacion.json'
if(!(Test-Path $receipt)) { throw 'Primero instale y verifique Prometheus con Instalar-Prometheus.ps1.' }
$PromInstallation=Get-Content $receipt -Raw | ConvertFrom-Json
$PromExecutable=Join-Path $PromInstallation.InstallDirectory 'prometheus.exe'
$PromtoolExecutable=Join-Path $PromInstallation.InstallDirectory 'promtool.exe'
function Test-PromConfig {
    if(!(Test-Path $PromConfig)) { throw 'No existe la configuracion academica de siete jobs.' }
    if((Get-FileHash $PromtoolExecutable -Algorithm SHA256).Hash -ne $PromInstallation.PromtoolExecutableSHA256) { throw 'promtool.exe no coincide con la instalacion verificada.' }
    $id=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $stdout=Join-Path $PromRuntime "promtool-$id.stdout.log"
    $stderr=Join-Path $PromRuntime "promtool-$id.stderr.log"
    $process=Start-Process $PromtoolExecutable -ArgumentList @('check','config',('"'+$PromConfig+'"')) -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null=$process.Handle;$process.WaitForExit();$process.WaitForExit()
    $text=([IO.File]::ReadAllText($stdout)+[IO.File]::ReadAllText($stderr)).Trim()
    # No sustituir evidencias historicas al volver a iniciar el mismo servidor.
    $historical=Test-Path (Join-Path $PromEvidence 'VALIDACION-PROMTOOL.json')
    $textFile=if($historical) { Join-Path $PromRuntime "promtool-$id.txt" } else { Join-Path $PromEvidence 'promtool-check-config.txt' }
    [IO.File]::WriteAllText($textFile,$text+"`n",(New-Object Text.UTF8Encoding($false)))
    $result=[pscustomobject]@{ExecutableVersion=$PromInstallation.Version;Command='promtool.exe check config';AbsoluteConfigPath=$PromConfig;ConfigSHA256=(Get-FileHash $PromConfig -Algorithm SHA256).Hash;ExitCode=$process.ExitCode;Valid=($process.ExitCode -eq 0);Output=$text;Timestamp=(Get-Date).ToString('o')}
    $jsonFile=if($historical) { Join-Path $PromRuntime "promtool-$id.json" } else { Join-Path $PromEvidence 'VALIDACION-PROMTOOL.json' }
    $result | ConvertTo-Json -Depth 5 | Set-Content $jsonFile -Encoding UTF8
    if(!$result.Valid) { throw 'promtool rechaza la configuracion. Prometheus no se inicia.' }
    return $result
}
