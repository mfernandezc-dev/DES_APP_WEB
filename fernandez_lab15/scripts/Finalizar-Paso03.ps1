$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Huellas-Bases.ps1')
$runtime=Join-Path $Lab15Root '.runtime\paso03'
$evidence=Join-Path $Lab15Root 'evidencias\02-micrometer'
$regression=Get-Content (Join-Path $evidence 'REGRESION-ACTUATOR.json') -Raw | ConvertFrom-Json
$prometheus=Get-Content (Join-Path $evidence 'PROMETHEUS-HTTP.json') -Raw | ConvertFrom-Json
$dependencies=Get-Content (Join-Path $evidence 'DEPENDENCIAS-PASO03.json') -Raw | ConvertFrom-Json
$captures=Get-Content (Join-Path $evidence 'CAPTURAS-PASO03.json') -Raw | ConvertFrom-Json
$integrity=Get-Content (Join-Path $runtime 'integridad-resultado.json') -Raw | ConvertFrom-Json
$registry=Get-Content (Join-Path $runtime 'procesos.json') -Raw | ConvertFrom-Json
$initial=Get-Content (Join-Path $runtime 'procesos-iniciales.json') -Raw | ConvertFrom-Json
$builds=Get-Content (Join-Path $runtime 'compilacion-todos.json') -Raw | ConvertFrom-Json
$listeners=@(Get-NetTCPConnection -State Listen)
$processChecks=@();$effective=@();$protections=@();$proxyChecks=@();$finalPrometheus=@()
foreach($record in $registry) {
    $process=Get-CimInstance Win32_Process -Filter "ProcessId=$($record.PID)"
    $actual=Get-Process -Id $record.PID -ErrorAction Stop
    $same=$process -and $process.ExecutablePath -eq $record.Java -and $process.CommandLine -like "*@../.runtime/paso03/$($record.Service).args*" -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $record.StartTimeUtc
    $ownListeners=@($listeners | Where-Object OwningProcess -eq $record.PID)
    $onlyLocal=$ownListeners.Count -eq 1 -and $ownListeners[0].LocalAddress -eq '127.0.0.1' -and $ownListeners[0].LocalPort -eq $record.Port
    $health=Invoke-RestMethod "http://localhost:$($record.Port)/actuator/health" -Headers @{Accept='application/json'} -TimeoutSec 15
    $prometheusUrl="http://localhost:$($record.Port)/actuator/prometheus"
    $live=Invoke-WebRequest $prometheusUrl -UseBasicParsing -Headers @{Accept='text/plain;version=0.0.4'} -TimeoutSec 15
    $liveText=if($live.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($live.Content) } else { [string]$live.Content }
    $liveType=[string]$live.Headers['Content-Type']
    $liveValid=$live.StatusCode -eq 200 -and $liveType -like 'text/plain*' -and $liveText -match '(?m)^# HELP ' -and $liveText -match '(?m)^# TYPE ' -and $liveText -match '(?m)^[A-Za-z_:][A-Za-z0-9_:]*(?:\{[^\r\n]*\})?\s+[-+]?\d'
    $finalPrometheus += [pscustomobject]@{Service=$record.Service;Url=$prometheusUrl;Http=[int]$live.StatusCode;ContentType=$liveType;Valid=$liveValid;Timestamp=(Get-Date).ToString('o')}
    $build=$builds | Where-Object Service -eq $record.Service
    $jarHash=(Get-FileHash $record.Jar -Algorithm SHA256).Hash
    $processChecks += [pscustomobject]@{Service=$record.Service;PID=$record.PID;Port=$record.Port;SameProcess=[bool]$same;LocalhostOnly=$onlyLocal;Health=$health.status;HealthHttp=200;JarSHA256=$jarHash;CurrentBuildMatches=($jarHash -eq $build.JarSHA256 -and $jarHash -eq $record.JarSHA256);Stdout=$record.Stdout.Substring($Lab15Root.Length+1).Replace('\','/');Stderr=$record.Stderr.Substring($Lab15Root.Length+1).Replace('\','/')}
    $protections += Get-Content (Join-Path $runtime "proteccion-$($record.Service).json") -Raw | ConvertFrom-Json
    $safe=[ordered]@{'server.address'='127.0.0.1';'management.endpoints.web.exposure.include'='*';'management.endpoint.health.show-details'='always';'management.prometheus.metrics.export.enabled'='true'}
    if($record.Service -in $Lab15Business) {
        $safe['spring.profiles.active']='dev';$safe['spring.cloud.config.label']=$Lab15Commit
        $safe['spring.jpa.hibernate.ddl-auto']='validate';$safe['spring.jpa.properties.hibernate.hbm2ddl.auto']='validate'
        $safe['spring.jpa.generate-ddl']='false';$safe['spring.sql.init.mode']='never'
        $safe['spring.flyway.enabled']='false';$safe['spring.liquibase.enabled']='false'
        $safe['spring.datasource.hikari.read-only']='true';$safe['spring.datasource.hikari.connection-init-sql']='SET SESSION TRANSACTION READ ONLY'
    }
    if($record.Service -eq 'gateway-service') { $safe['spring.cloud.gateway.server.webflux.discovery.locator.enabled']='false' }
    $argText=Get-Content $record.ArgsFile -Raw
    foreach($key in $safe.Keys) {
        $url="http://localhost:$($record.Port)/actuator/env/$key"
        $body=Invoke-RestMethod $url -Headers @{Accept='application/json'} -TimeoutSec 15
        $argumentMatches=$argText.Contains('"--'+$key+'='+$safe[$key]+'"')
        $valid=$body.property.source -eq 'commandLineArgs' -and $argumentMatches
        $effective += [pscustomobject]@{Service=$record.Service;Url=$url;Http=200;Property=$key;ExpectedNonSensitiveValue=$safe[$key];EffectiveProperty=$body.property;ActiveProfiles=$body.activeProfiles;ArgumentMatches=$argumentMatches;Valid=$valid}
    }
    $url="http://localhost:8080/$($record.Service)/actuator/prometheus"
    $status=0
    try { $response=Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 10; $status=[int]$response.StatusCode } catch { if($_.Exception.Response) { $status=[int]$_.Exception.Response.StatusCode } }
    $proxyChecks += [pscustomobject]@{Url=$url;Http=$status;Blocked=($status -eq 404)}
}
$databaseBefore=Get-Content (Join-Path $runtime 'bases-iniciales.json') -Raw | ConvertFrom-Json
$databaseAfter=@(Get-Lab15DatabaseSnapshot -Paso 03)
$databaseUnchanged=($databaseBefore | ConvertTo-Json -Depth 12 -Compress) -eq ($databaseAfter | ConvertTo-Json -Depth 12 -Compress)
$databaseAfter | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $runtime 'bases-finales.json') -Encoding UTF8
$eureka=Invoke-RestMethod 'http://localhost:8761/eureka/apps' -Headers @{Accept='application/json'} -TimeoutSec 15
$applications=@($eureka.applications.application)
$eurekaRows=@($applications | ForEach-Object { $app=$_; foreach($instance in @($app.instance)) { [pscustomobject]@{Name=$app.name;Status=$instance.status;Ip=$instance.ipAddr;Port=$instance.port.'$'} } })
$expected=@('CATEGORIA-SERVICE','PRODUCTO-SERVICE','CLIENTE-SERVICE','PEDIDO-SERVICE','GATEWAY-SERVICE')
$eurekaValid=$eurekaRows.Count -eq 5 -and @($eurekaRows | Where-Object { $_.Status -ne 'UP' -or $_.Ip -ne '127.0.0.1' -or $_.Name -notin $expected }).Count -eq 0
$java=@(Get-CimInstance Win32_Process -Filter "name='java.exe' OR name='javaw.exe'")
$ownedJava=@($java | Where-Object CommandLine -like '*@../.runtime/paso03/*.args*')
$oldJava=@($java | Where-Object CommandLine -like '*@../.runtime/paso02/*.args*')
$ignored=@(git check-ignore -- '.runtime/paso03/procesos.json' '.runtime/paso03/producto-service.args' '.runtime/paso03/capturas-originales/01-producto-prometheus.png' 'producto-service/target/producto-service-0.0.1-SNAPSHOT.jar')
Add-Type -AssemblyName System.Drawing
$images=@()
foreach($capture in $captures.captures) {
    $file=Join-Path $evidence $capture.file
    $image=New-Object Drawing.Bitmap($file)
    try { $images += [pscustomobject]@{File=$capture.file;Width=$image.Width;Height=$image.Height;SHA256=(Get-FileHash $file -Algorithm SHA256).Hash;Redactions=@($capture.redactions).Count} } finally { $image.Dispose() }
}
$secretFindings=@()
foreach($file in Get-ChildItem $evidence -Recurse -File | Where-Object Extension -in '.json','.txt','.md') {
    $text=Get-Content $file.FullName -Raw
    if($text -match '(?i)"(password|passwd|token|secret|authorization|cookie|nro_dni|nroDni|email|direccion|apellido)"\s*:\s*"(?!\[REDACTADO\]|\*+)[^"\s][^"]*"' -or
       ($file.Extension -eq '.txt' -and $text -match '(?i)\b(path|file|directory)="[^"\r\n]*(?:[A-Za-z]:\\|/Users/|/home/)')) {
        $secretFindings += $file.Name
    }
}
$successful=$regression.Completed -and $prometheus.Completed -and $databaseUnchanged -and $eurekaValid -and
    $processChecks.Count -eq 7 -and @($processChecks | Where-Object { !$_.SameProcess -or !$_.LocalhostOnly -or !$_.CurrentBuildMatches -or $_.Health -ne 'UP' }).Count -eq 0 -and
    @($effective | Where-Object { !$_.Valid }).Count -eq 0 -and @($protections | Where-Object { !$_.valid }).Count -eq 0 -and
    @($proxyChecks | Where-Object { !$_.Blocked }).Count -eq 0 -and @($finalPrometheus | Where-Object { !$_.Valid }).Count -eq 0 -and $ownedJava.Count -eq 7 -and $oldJava.Count -eq 0 -and
    $images.Count -eq 10 -and !$captures.error -and $secretFindings.Count -eq 0 -and $ignored.Count -eq 4 -and
    $integrity.IndexUnchanged -and $integrity.PriorEvidenceUnchanged -and $integrity.ExternalGitStatusUnchanged -and
    @($integrity.ExternalChangedOrRemoved).Count -eq 0 -and @($integrity.ExternalAdded).Count -eq 0
$report=[ordered]@{Step='03';Timestamp=(Get-Date).ToString('o');Completed=[bool]$successful;JavaHome=$Lab15JavaHome;Java='26.0.2.1';Maven='3.9.16';Commit=$Lab15Commit;InitialProcesses=@($initial | ForEach-Object { $_ });Dependencies=$dependencies;Builds=@($builds | ForEach-Object { $_ });Processes=$processChecks;Protections=$protections;EffectivePropertyRecheck=$effective;Prometheus=$prometheus;FinalLivePrometheus=$finalPrometheus;Regression=$regression;EurekaFinal=[pscustomobject]@{Valid=$eurekaValid;Applications=$eurekaRows;NotConfiguredToRegister=@('config-server','eureka-server')};GatewayPrometheusIsolation=$proxyChecks;OwnedJavaProcesses=$ownedJava.Count;OldStep02Processes=$oldJava.Count;Database=[pscustomobject]@{Unchanged=$databaseUnchanged;Before=@($databaseBefore | ForEach-Object { $_ });After=@($databaseAfter | ForEach-Object { $_ })};Integrity=$integrity;Screenshots=$captures;ScreenshotAudit=$images;Security=[pscustomobject]@{SensitiveFindings=$secretFindings;OperationalFilesIgnored=($ignored.Count -eq 4);CompleteEnvSaved=$false;OriginalScrapesAndImagesOnlyInRuntime=$true;PersonalDataRedacted=$true};Step04=[pscustomobject]@{ReadyForAuthorization=[bool]$successful;Executed=$false;PrometheusServerInstalled=$false;GrafanaInstalled=$false;DockerExecuted=$false}}
$report | ConvertTo-Json -Depth 65 | Set-Content (Join-Path $evidence 'VERIFICACION-PASO03.json') -Encoding UTF8
[pscustomobject]@{Completed=$successful;Prometheus200=@($prometheus.Prometheus | Where-Object status -eq 200).Count;Actuator200=@($regression.Actuator | Where-Object Status -eq 200).Count;RunningProcesses=$processChecks.Count;RealScreenshots=$images.Count;DatabaseUnchanged=$databaseUnchanged;PriorEvidenceUnchanged=$integrity.PriorEvidenceUnchanged;SensitiveFindings=$secretFindings.Count} | Format-List
