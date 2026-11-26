$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Huellas-Bases.ps1')
. (Join-Path $PSScriptRoot 'Entorno-Prometheus.ps1')
$runtime=Join-Path $Lab15Root '.runtime\paso04'
$evidence=Join-Path $Lab15Root 'evidencias\03-prometheus'
$resumeBaseline=Get-Content (Join-Path $runtime 'reanudacion-antes.json') -Raw | ConvertFrom-Json
$installationRecheck=Get-Content (Join-Path $runtime 'instalacion-reverificada.json') -Raw | ConvertFrom-Json
$initial=Get-Content (Join-Path $runtime 'procesos-iniciales.json') -Raw | ConvertFrom-Json
$registry=Get-Content (Join-Path $Lab15Root '.runtime\paso03\procesos.json') -Raw | ConvertFrom-Json
$installation=Get-Content (Join-Path $evidence 'INSTALACION-PROMETHEUS.json') -Raw | ConvertFrom-Json
$validation=Get-Content (Join-Path $evidence 'VALIDACION-PROMTOOL.json') -Raw | ConvertFrom-Json
$queries=Get-Content (Join-Path $evidence 'CONSULTAS-PROMETHEUS.json') -Raw | ConvertFrom-Json
$regression=Get-Content (Join-Path $evidence 'REGRESION-ACTUATOR.json') -Raw | ConvertFrom-Json
$integrity=Get-Content (Join-Path $runtime 'integridad-resultado.json') -Raw | ConvertFrom-Json
$captureFile=Join-Path $evidence 'CAPTURAS-PASO04.json'
$captures=if(Test-Path $captureFile) { Get-Content $captureFile -Raw | ConvertFrom-Json } else { $null }
$listeners=@(Get-NetTCPConnection -State Listen)
$processChecks=@();$effective=@();$proxyChecks=@();$protections=@();$actuatorFinal=@()
$javaProcesses=@(Get-CimInstance Win32_Process -Filter "name='java.exe' OR name='javaw.exe'")
foreach($record in $registry) {
    $process=Get-CimInstance Win32_Process -Filter "ProcessId=$($record.PID)"
    $actual=Get-Process -Id $record.PID -ErrorAction Stop
    $before=$initial | Where-Object Service -eq $record.Service
    $same=$process -and $process.ExecutablePath -eq $record.Java -and $process.CommandLine -like "*@../.runtime/paso03/$($record.Service).args*" -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $before.StartTimeUtc -and $record.PID -eq $before.PID
    $own=@($listeners | Where-Object OwningProcess -eq $record.PID)
    $local=$own.Count -eq 1 -and $own[0].LocalAddress -eq '127.0.0.1' -and $own[0].LocalPort -eq $record.Port
    $health=Invoke-RestMethod "http://localhost:$($record.Port)/actuator/health" -Headers @{Accept='application/json'} -TimeoutSec 15
    $scrape=Invoke-WebRequest "http://localhost:$($record.Port)/actuator/prometheus" -UseBasicParsing -Headers @{Accept='text/plain;version=0.0.4'} -TimeoutSec 15
    $instances=@($javaProcesses | Where-Object { $_.CommandLine -like "*@../.runtime/paso03/$($record.Service).args*" }).Count
    $processChecks += [pscustomobject]@{Service=$record.Service;PID=$record.PID;Port=$record.Port;SameProcessAsBefore=[bool]$same;Instances=$instances;LocalhostOnly=$local;Health=$health.status;HealthHTTP=200;PrometheusHTTP=[int]$scrape.StatusCode;JarUnchanged=((Get-FileHash $record.Jar -Algorithm SHA256).Hash -eq $record.JarSHA256)}
    $actuatorFinal += [pscustomobject]@{Service=$record.Service;Url="http://localhost:$($record.Port)/actuator/health";Http=200;Valid=($health.status -eq 'UP')}
    foreach($endpoint in @('','/metrics')) {
        $url="http://localhost:$($record.Port)/actuator$endpoint"
        $body=Invoke-RestMethod $url -Headers @{Accept='application/json'} -TimeoutSec 15
        $valid=if($endpoint) { 'jvm.memory.used' -in $body.names -and 'http.server.requests' -in $body.names } else { [bool]$body._links.prometheus.href }
        $actuatorFinal += [pscustomobject]@{Service=$record.Service;Url=$url;Http=200;Valid=[bool]$valid}
    }
    $protections += Get-Content (Join-Path $Lab15Root ".runtime\paso03\proteccion-$($record.Service).json") -Raw | ConvertFrom-Json
    $safe=[ordered]@{'server.address'='127.0.0.1';'management.prometheus.metrics.export.enabled'='true'}
    if($record.Service -eq 'config-server') { $safe['spring.cloud.config.server.git.default-label']=$Lab15Commit }
    if($record.Service -in $Lab15Business) {
        $safe['spring.profiles.active']='dev';$safe['spring.cloud.config.label']=$Lab15Commit
        $safe['spring.jpa.hibernate.ddl-auto']='validate';$safe['spring.jpa.properties.hibernate.hbm2ddl.auto']='validate'
        $safe['spring.jpa.generate-ddl']='false';$safe['spring.sql.init.mode']='never';$safe['spring.flyway.enabled']='false';$safe['spring.liquibase.enabled']='false'
        $safe['spring.datasource.hikari.read-only']='true';$safe['spring.datasource.hikari.connection-init-sql']='SET SESSION TRANSACTION READ ONLY'
    }
    if($record.Service -eq 'gateway-service') { $safe['spring.cloud.gateway.server.webflux.discovery.locator.enabled']='false' }
    $argText=Get-Content $record.ArgsFile -Raw
    foreach($key in $safe.Keys) {
        $url="http://localhost:$($record.Port)/actuator/env/$key"
        $body=Invoke-RestMethod $url -Headers @{Accept='application/json'} -TimeoutSec 15
        $matchesArgument=$argText.Contains('"--'+$key+'='+$safe[$key]+'"')
        $effective += [pscustomobject]@{Service=$record.Service;Url=$url;Http=200;Property=$key;ExpectedNonSensitiveValue=$safe[$key];EffectiveProperty=$body.property;ActiveProfiles=$body.activeProfiles;Valid=($matchesArgument -and $body.property.source -eq 'commandLineArgs')}
    }
    $url="http://localhost:8080/$($record.Service)/actuator/prometheus";$status=0
    try { $result=Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 10;$status=[int]$result.StatusCode } catch { if($_.Exception.Response) { $status=[int]$_.Exception.Response.StatusCode } }
    $proxyChecks += [pscustomobject]@{Url=$url;Http=$status;Blocked=($status -eq 404)}
}
$dbBefore=Get-Content (Join-Path $runtime 'bases-antes.json') -Raw | ConvertFrom-Json
$dbAfter=@(Get-Lab15DatabaseSnapshot -Paso 03)
$databaseUnchanged=($dbBefore | ConvertTo-Json -Depth 12 -Compress) -eq ($dbAfter | ConvertTo-Json -Depth 12 -Compress)
$dbAfter | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $runtime 'bases-finales.json') -Encoding UTF8
$promRecord=Get-Content (Join-Path $PromRuntime 'proceso.json') -Raw | ConvertFrom-Json
$promProcess=Get-CimInstance Win32_Process -Filter "ProcessId=$($promRecord.PID)"
$promActual=Get-Process -Id $promRecord.PID
$promListeners=@($listeners | Where-Object OwningProcess -eq $promRecord.PID)
$promSame=$promProcess -and $promProcess.ExecutablePath -eq $promRecord.Executable -and $promActual.StartTime.ToUniversalTime().ToString('o') -eq $promRecord.StartTimeUtc
foreach($argument in $promRecord.Arguments) { if($promProcess.CommandLine.IndexOf($argument,[StringComparison]::OrdinalIgnoreCase) -lt 0) { $promSame=$false } }
$promLocal=$promListeners.Count -eq 1 -and $promListeners[0].LocalAddress -eq '127.0.0.1' -and $promListeners[0].LocalPort -eq 9090
$promCount=@(Get-CimInstance Win32_Process -Filter "name='prometheus.exe'").Count
# La API Go emite JSON UTF-8 sin charset; Windows PowerShell 5.1 puede
# interpretar el simbolo de grado de la ruta como Latin-1. Decodificar bytes.
function Read-PrometheusJson([string]$Url) {
    $response=Invoke-WebRequest $Url -UseBasicParsing -TimeoutSec 15
    return ([Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray()) | ConvertFrom-Json)
}
$flagsBody=Read-PrometheusJson 'http://localhost:9090/api/v1/status/flags'
$buildBody=Read-PrometheusJson 'http://localhost:9090/api/v1/status/buildinfo'
$liveSettings=[pscustomobject]@{Version=$buildBody.data.version;ListenAddress=$flagsBody.data.'web.listen-address';ConfigFile=$flagsBody.data.'config.file';Retention=$flagsBody.data.'storage.tsdb.retention.time';AdminApiEnabled=$flagsBody.data.'web.enable-admin-api';LifecycleEnabled=$flagsBody.data.'web.enable-lifecycle'}
$liveSettingsValid=$flagsBody.status -eq 'success' -and $buildBody.status -eq 'success' -and $liveSettings.Version -eq $installation.Version -and $liveSettings.ListenAddress -eq '127.0.0.1:9090' -and $liveSettings.ConfigFile -eq $PromConfig -and $liveSettings.Retention -eq '1d' -and $liveSettings.AdminApiEnabled -eq 'false' -and $liveSettings.LifecycleEnabled -eq 'false'
$binariesUnchanged=(Get-FileHash $promRecord.Executable -Algorithm SHA256).Hash -eq $installation.PrometheusExecutableSHA256 -and (Get-FileHash $PromtoolExecutable -Algorithm SHA256).Hash -eq $installation.PromtoolExecutableSHA256
$serverHealth=@()
foreach($endpoint in @('/','/-/healthy','/-/ready','/targets')) { $result=Invoke-WebRequest "http://localhost:9090$endpoint" -UseBasicParsing -TimeoutSec 15; $serverHealth += [pscustomobject]@{Url="http://localhost:9090$endpoint";Http=[int]$result.StatusCode} }
$targets=Invoke-RestMethod 'http://localhost:9090/api/v1/targets' -TimeoutSec 15
$targets | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $evidence 'targets-verificacion-final.json') -Encoding UTF8
$active=@($targets.data.activeTargets)
$targetsValid=$active.Count -eq 7 -and @($active | Where-Object { $_.health -ne 'up' -or $_.lastError -ne '' -or $_.scrapeInterval -ne '5s' -or $_.scrapeTimeout -ne '4s' }).Count -eq 0
foreach($record in $registry) {
    $matching=@($active | Where-Object { $_.labels.job -eq $record.Service -and $_.labels.instance -eq "127.0.0.1:$($record.Port)" -and $_.scrapeUrl -eq "http://127.0.0.1:$($record.Port)/actuator/prometheus" })
    if($matching.Count -ne 1) { $targetsValid=$false }
}
$basicQueries=@()
foreach($expr in @('up','count(up)','sum(up)','count(up == 0) or vector(0)')) {
    $url='http://localhost:9090/api/v1/query?query='+[Uri]::EscapeDataString($expr)
    $body=Invoke-RestMethod $url -TimeoutSec 15
    $basicQueries += [pscustomobject]@{Query=$expr;Http=200;Response=$body}
}
$eureka=Invoke-RestMethod 'http://localhost:8761/eureka/apps' -Headers @{Accept='application/json'} -TimeoutSec 15
$eurekaRows=@($eureka.applications.application | ForEach-Object { $app=$_;foreach($instance in @($app.instance)) { [pscustomobject]@{Name=$app.name;Status=$instance.status;Ip=$instance.ipAddr} } })
$eurekaExpected=@('CATEGORIA-SERVICE','PRODUCTO-SERVICE','CLIENTE-SERVICE','PEDIDO-SERVICE','GATEWAY-SERVICE')
$eurekaValid=$eurekaRows.Count -eq 5 -and @($eurekaExpected | Where-Object { $_ -notin $eurekaRows.Name }).Count -eq 0 -and @($eurekaRows | Where-Object { $_.Status -ne 'UP' -or $_.Ip -ne '127.0.0.1' }).Count -eq 0
$dbListener=@($listeners | Where-Object LocalPort -eq 3306)
$dbPid=if($dbListener.Count) { $dbListener[0].OwningProcess } else { 0 }
$dbProcess=Get-CimInstance Win32_Process -Filter "ProcessId=$dbPid"
$dbRunning=$dbPid -eq 12400 -and $dbProcess.ExecutablePath -like '*\xampp\mysql\bin\mysqld.exe'
$ignored=@(git check-ignore -- '.runtime/prometheus/data/wal' '.runtime/prometheus/proceso.json' '.runtime/paso04/prometheus-3.13.5.windows-amd64.zip' '.runtime/paso04/browser-profile/Local State')
$installationOutsideGit=$installation.InstallDirectory -notlike "$((Split-Path $Lab15Root -Parent))\*"
$sensitive=@()
foreach($file in Get-ChildItem $evidence -Recurse -File | Where-Object Extension -in '.json','.txt','.md') {
    $text=Get-Content $file.FullName -Raw
    if($text -match '(?i)"(password|passwd|token|secret|authorization|cookie|nro_dni|nroDni|email|direccion|apellido)"\s*:\s*"(?!\[REDACTADO\]|\*+)[^"\s][^"]*"') { $sensitive += $file.Name }
}
$images=@()
if($captures) {
    Add-Type -AssemblyName System.Drawing
    foreach($capture in $captures.captures) {
        $file=Join-Path $evidence $capture.file;$image=New-Object Drawing.Bitmap($file)
        try { $images += [pscustomobject]@{File=$capture.file;Width=$image.Width;Height=$image.Height;SHA256=(Get-FileHash $file -Algorithm SHA256).Hash} } finally { $image.Dispose() }
    }
}
$manifest=Get-Content (Join-Path $runtime 'capturas.json') -Raw | ConvertFrom-Json
$expectedCaptures=@($manifest.captures | ForEach-Object { $_[0] })
$captureIssues=@($expectedCaptures | Where-Object { $_ -notin $images.File })
$capturesValid=$captures -and !$captures.error -and $images.Count -eq $expectedCaptures.Count -and $images.Count -ge 17 -and $captureIssues.Count -eq 0 -and @($images | Where-Object { $_.Width -lt 1000 -or $_.Height -lt 600 }).Count -eq 0 -and @($captures.captures | Where-Object { $_.bytes -ne (Get-Item (Join-Path $evidence $_.file)).Length -or (!$_.url.StartsWith('file:') -and $_.status -ne 200) }).Count -eq 0
$preserved=@();$changedExisting=@()
foreach($file in $resumeBaseline.ExistingEvidence) {
    if($file.Path -eq 'evidencias/03-prometheus/CAPTURAS-PASO04.json') { continue }
    $full=Join-Path $Lab15Root $file.Path
    if((Test-Path -LiteralPath $full) -and (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash -eq $file.SHA256) { $preserved += $file.Path } else { $changedExisting += $file.Path }
}
$recovery=[pscustomobject]@{BaselineTimestamp=$resumeBaseline.Timestamp;OriginalPromptAvailable=$false;RecoveredInstructions=@('README.md','scripts/Preparar-Capturas-Paso04.mjs','scripts/Finalizar-Paso04.ps1','.runtime/paso04/integridad-antes.json');PreviouslyCompleted=@('Instalacion y checksum','Configuracion y promtool','Siete targets UP','19 PromQL antes y despues','120 GET y cuatro query_range','Regresion Actuator','14 capturas reales');PendingAtResume=@('Capturas 15 y 16','Cobertura visual de targets restantes','Verificacion final e integridad','PASO04.md','VERIFICACION-PASO04.json');ExistingEvidencePreserved=$preserved.Count;ChangedOrMissingExistingEvidence=$changedExisting;AllExistingResultsPreserved=($changedExisting.Count -eq 0);OriginalScreenshotsPreserved=@($preserved | Where-Object { $_ -like '*.png' }).Count;UpdatedMetadataOnly='CAPTURAS-PASO04.json: agregadas 15,16,17 y cerrado error; original archivado en .runtime/paso04/CAPTURAS-PASO04-interrumpido.json';InterruptedCaptureError=$resumeBaseline.ExistingScreenshotError;NewScreenshots=@('15-suma-servicios-up.png','16-servicios-down.png','17-targets-up-continuacion.png');TrafficRepeated=$false;ServicesRestarted=$false;PrometheusReinstalled=$false;RemainingStep04Activities=@()}
$documentationExists=(Test-Path (Join-Path $evidence 'PASO04.md')) -and (Test-Path (Join-Path $Lab15Root 'README.md'))
$sameConfig=(Get-FileHash $PromConfig -Algorithm SHA256).Hash -eq $validation.ConfigSHA256 -and $promRecord.ConfigSHA256 -eq $validation.ConfigSHA256
$upResult=@(($basicQueries | Where-Object Query -eq 'up').Response.data.result)
$basicValid=$upResult.Count -eq 7 -and @($upResult | Where-Object { $_.value[1] -ne '1' }).Count -eq 0
foreach($expected in @(@('count(up)','7'),@('sum(up)','7'),@('count(up == 0) or vector(0)','0'))) {
    $actualQuery=$basicQueries | Where-Object Query -eq $expected[0]
    if($actualQuery.Response.status -ne 'success' -or $actualQuery.Response.data.result[0].value[1] -ne $expected[1]) { $basicValid=$false }
}
$successful=$queries.Completed -and $regression.Completed -and $installation.SHA256Verified -and $validation.Valid -and $sameConfig -and $binariesUnchanged -and $liveSettingsValid -and $installationRecheck.ArchiveChecksumMatches -and $installationRecheck.PromtoolExitCode -eq 0 -and
    $targetsValid -and $basicValid -and $promSame -and $promLocal -and $promCount -eq 1 -and $databaseUnchanged -and $dbRunning -and
    $processChecks.Count -eq 7 -and @($processChecks | Where-Object { !$_.SameProcessAsBefore -or $_.Instances -ne 1 -or !$_.LocalhostOnly -or !$_.JarUnchanged -or $_.Health -ne 'UP' -or $_.PrometheusHTTP -ne 200 }).Count -eq 0 -and
    @($effective | Where-Object { !$_.Valid }).Count -eq 0 -and @($proxyChecks | Where-Object { !$_.Blocked }).Count -eq 0 -and
    $eurekaValid -and $actuatorFinal.Count -eq 21 -and @($actuatorFinal | Where-Object { !$_.Valid -or $_.Http -ne 200 }).Count -eq 0 -and
    $integrity.PriorEvidenceUnchanged -and $integrity.IndexUnchanged -and $integrity.ExternalGitStatusUnchanged -and @($integrity.ExternalChangedOrRemoved).Count -eq 0 -and @($integrity.ExternalAdded).Count -eq 0 -and
    $integrity.Lab14Unchanged -and $integrity.HeadUnchanged -and $ignored.Count -eq 4 -and $sensitive.Count -eq 0 -and $capturesValid -and $documentationExists -and $recovery.AllExistingResultsPreserved -and $recovery.OriginalScreenshotsPreserved -eq 14
$report=[ordered]@{Step='04';Timestamp=(Get-Date).ToString('o');Completed=[bool]$successful;Installation=$installation;Promtool=$validation;ConfigurationSHA256=$validation.ConfigSHA256;PrometheusProcess=[pscustomobject]@{PID=$promRecord.PID;Port=9090;Version=$promRecord.Version;Executable=$promRecord.Executable;SameProcess=[bool]$promSame;LocalhostOnly=$promLocal;Processes=$promCount;Retention=$promRecord.Retention;AdminApiEnabled=$false;LifecycleEnabled=$false};ServerHTTP=$serverHealth;Targets=$targets;BasicQueriesFinal=$basicQueries;QueriesAndTraffic=$queries;Microservices=$processChecks;Regression=$regression;EurekaFinal=$eurekaRows;GatewayIsolation=$proxyChecks;EffectivePropertyRecheck=$effective;PriorActualContextProtections=$protections;ProtectionScope='Mismos PID/contextos del PASO 03: Hibernate/JDBC verificados por la sonda de arranque; precedencia efectiva reconsultada sin revelar valores ni reiniciar; instantaneas JDBC nuevas de solo lectura';MariaDB=[pscustomobject]@{PID=$dbPid;Port=3306;SameXamppProcess=$dbRunning};Database=[pscustomobject]@{Unchanged=$databaseUnchanged;Before=@($dbBefore | ForEach-Object { $_ });After=@($dbAfter | ForEach-Object { $_ })};Integrity=$integrity;Screenshots=$captures;ScreenshotAudit=$images;Security=[pscustomobject]@{SensitiveFindings=$sensitive;OperationalFilesIgnored=($ignored.Count -eq 4);InstallationOutsideGit=$installationOutsideGit;NoCompleteEnvSaved=$true};Step05=[pscustomobject]@{ReadyForAuthorization=[bool]$successful;Executed=$false;GrafanaInstalled=$false;DockerExecuted=$false}}
$report['Recovery']=$recovery
$report['InstallationRecheck']=$installationRecheck
$report['PrometheusLiveSettings']=$liveSettings
$report['BinariesUnchanged']=$binariesUnchanged
$report['ActuatorFinal']=$actuatorFinal
$report['ScreenshotVerification']=[pscustomobject]@{Valid=[bool]$capturesValid;Expected=$expectedCaptures;Missing=$captureIssues;Original14Preserved=($recovery.OriginalScreenshotsPreserved -eq 14)}
$report['Documentation']=[pscustomobject]@{Report='PASO04.md';Exists=$documentationExists;SHA256=(Get-FileHash (Join-Path $evidence 'PASO04.md') -Algorithm SHA256).Hash;ReadmeSHA256=(Get-FileHash (Join-Path $Lab15Root 'README.md') -Algorithm SHA256).Hash}
$report | ConvertTo-Json -Depth 70 | Set-Content (Join-Path $evidence 'VERIFICACION-PASO04.json') -Encoding UTF8
[pscustomobject]@{Completed=$successful;PrometheusPID=$promRecord.PID;TargetsUP=@($active | Where-Object health -eq 'up').Count;TargetsDOWN=@($active | Where-Object health -ne 'up').Count;JavaSamePIDs=@($processChecks | Where-Object SameProcessAsBefore).Count;Actuator200=@($regression.Actuator | Where-Object Status -eq 200).Count;DatabaseUnchanged=$databaseUnchanged;PriorEvidenceUnchanged=$integrity.PriorEvidenceUnchanged;RealScreenshots=$images.Count;SensitiveFindings=$sensitive.Count} | Format-List
if(!$successful) { throw 'PASO 04 no completado: revisar las comprobaciones en VERIFICACION-PASO04.json.' }
