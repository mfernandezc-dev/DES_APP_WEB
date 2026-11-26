# Consolidacion de evidencias; no inicia ni detiene microservicios.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Huellas-Bases.ps1')
$evidence = Join-Path $Lab15Root 'evidencias\01-actuator'
$runtime = Join-Path $Lab15Root '.runtime\paso02'
$path = Join-Path $evidence 'VERIFICACION-PASO02.json'
$report = Get-Content $path -Raw | ConvertFrom-Json
function Set-ReportField([string]$Name, $Value) { $report | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force }
function Convert-HttpJson($Response) {
    $text = if ($Response.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($Response.Content) } else { [string]$Response.Content }
    return ($text | ConvertFrom-Json)
}
$capturePath = Join-Path $evidence 'CAPTURAS-PASO02.json'
if (Test-Path $capturePath) { $report.Screenshots = Get-Content $capturePath -Raw | ConvertFrom-Json }
$audit = @()
Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach ($service in $Lab15Ports.Keys) {
    [xml]$pom = Get-Content (Join-Path $Lab15Root "$service\pom.xml") -Raw
    $direct = @($pom.project.dependencies.dependency | Where-Object artifactId -eq 'spring-boot-starter-actuator')
    $jar = Join-Path $Lab15Root "$service\target\$service-0.0.1-SNAPSHOT.jar"
    $zip = [IO.Compression.ZipFile]::OpenRead($jar)
    try {
        $prometheus = @($zip.Entries | Where-Object FullName -match 'BOOT-INF/lib/.*(micrometer-registry-prometheus|prometheus).*\.jar$')
        $audit += [pscustomobject]@{Service=$service;DirectActuatorDeclarations=$direct.Count;SpringBoot=$pom.project.parent.version;SpringCloud=$pom.project.properties.'spring-cloud.version';JavaLevel=$pom.project.properties.'java.version';PrometheusLibraries=$prometheus.Count;JarSHA256=(Get-FileHash $jar -Algorithm SHA256).Hash}
    } finally { $zip.Dispose() }
}
Set-ReportField 'DependencyAudit' $audit
# Normalizar arrays deserializados por Windows PowerShell 5.1 (sin metadatos Count/value).
$report.Builds = @((Get-Content (Join-Path $Lab15Root '.runtime\compilacion-todos.json') -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
$report.Database.Before = @((Get-Content (Join-Path $runtime 'bases-antes.json') -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
$report.Database.After = @((Get-Content (Join-Path $runtime 'bases-despues.json') -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
$resilience = @()
$circuits = [ordered]@{'producto-service'='categoriaService';'cliente-service'='pedidoService';'pedido-service'='productoService'}
foreach ($service in $circuits.Keys) {
    foreach ($kind in @('successful','failed','ignored')) {
        $url = "http://localhost:$($Lab15Ports[$service])/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:$($circuits[$service])&tag=kind:$kind"
        $response = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 15 -Headers @{Accept='application/json'}
        $body = Convert-HttpJson $response
        $file = "respuestas/$service-circuito-$kind.json"
        [ordered]@{Method='GET';Url=$url;Status=[int]$response.StatusCode;Body=$body;Timestamp=(Get-Date).ToString('o')} | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $evidence $file) -Encoding UTF8
        $resilience += [pscustomobject]@{Service=$service;Circuit=$circuits[$service];Kind=$kind;Http=[int]$response.StatusCode;Count=($body.measurements | Where-Object statistic -eq 'COUNT').value;Evidence=$file}
    }
}
Set-ReportField 'FinalResilienceCalls' $resilience
$registry = Get-Content (Join-Path $runtime 'procesos.json') -Raw | ConvertFrom-Json
$listeners = @(Get-NetTCPConnection -State Listen)
$checks = @()
$effective = @()
foreach ($record in $registry) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($record.PID)"
    $actual = Get-Process -Id $record.PID -ErrorAction Stop
    $owned = $process -and $process.ExecutablePath -eq $record.Java -and
        $process.CommandLine -like "*@../.runtime/paso02/$($record.Service).args*" -and
        $actual.StartTime.ToUniversalTime().ToString('o') -eq $record.StartTimeUtc
    $ownListeners = @($listeners | Where-Object OwningProcess -eq $record.PID)
    $onlyLocal = $ownListeners.Count -gt 0 -and @($ownListeners | Where-Object { $_.LocalAddress -notin @('127.0.0.1','::1') }).Count -eq 0
    $response = Invoke-WebRequest "http://localhost:$($record.Port)/actuator/health" -UseBasicParsing -TimeoutSec 15 -Headers @{Accept='application/json'}
    $health = Convert-HttpJson $response
    $argsHash = (Get-FileHash $record.ArgsFile -Algorithm SHA256).Hash
    $checks += [pscustomobject]@{Service=$record.Service;PID=$record.PID;Port=$record.Port;SameProcess=[bool]$owned;LocalhostOnly=$onlyLocal;ListeningPorts=@($ownListeners.LocalPort);HealthHttp=[int]$response.StatusCode;Health=$health.status;ArgsSHA256=$argsHash}
    $safeProperties = [ordered]@{'server.address'='127.0.0.1';'management.endpoints.web.exposure.include'='*';'management.endpoint.health.show-details'='always'}
    if ($record.Service -in $Lab15Business) {
        $safeProperties['spring.profiles.active']='dev'
        $safeProperties['spring.cloud.config.label']=$Lab15Commit
        $safeProperties['spring.jpa.hibernate.ddl-auto']='validate'
        $safeProperties['spring.jpa.properties.hibernate.hbm2ddl.auto']='validate'
        $safeProperties['spring.jpa.generate-ddl']='false'
        $safeProperties['spring.sql.init.mode']='never'
        $safeProperties['spring.flyway.enabled']='false'
        $safeProperties['spring.liquibase.enabled']='false'
        $safeProperties['spring.datasource.hikari.read-only']='true'
        $safeProperties['spring.datasource.hikari.connection-init-sql']='SET SESSION TRANSACTION READ ONLY'
    }
    $argText = Get-Content $record.ArgsFile -Raw
    foreach ($key in $safeProperties.Keys) {
        # Consulta exclusivamente propiedades no sensibles; nunca /env completo.
        $url = "http://localhost:$($record.Port)/actuator/env/$key"
        $response = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 15 -Headers @{Accept='application/json'}
        $body = Convert-HttpJson $response
        $argumentMatches = $argText.Contains('"--' + $key + '=' + $safeProperties[$key] + '"')
        $sourceMatches = $body.property.source -eq 'commandLineArgs'
        $effective += [pscustomobject]@{Service=$record.Service;Url=$url;Http=[int]$response.StatusCode;Property=$key;ExpectedNonSensitiveValue=$safeProperties[$key];HttpEffectiveProperty=$body.property;ActiveProfiles=$body.activeProfiles;ArgumentMatches=$argumentMatches;EffectiveSourceMatches=$sourceMatches;Valid=($argumentMatches -and $sourceMatches)}
    }
}
Set-ReportField 'FinalProcessCheck' $checks
Set-ReportField 'EffectivePropertyRecheck' $effective
$databaseAfter = @(Get-Lab15DatabaseSnapshot)
$databaseBefore = Get-Content (Join-Path $runtime 'bases-antes.json') -Raw | ConvertFrom-Json
$databaseSame = ($databaseBefore | ConvertTo-Json -Depth 10 -Compress) -eq ($databaseAfter | ConvertTo-Json -Depth 10 -Compress)
Set-ReportField 'FinalDatabaseCheck' ([pscustomobject]@{Unchanged=$databaseSame;Timestamp=(Get-Date).ToString('o');After=@($databaseAfter | ForEach-Object { $_ })})
$ignorePaths = @('.runtime/paso02/procesos.json','.runtime/paso02/producto-service.args','producto-service/target/producto-service-0.0.1-SNAPSHOT.jar','.runtime/paso02/chrome-evidencias/Local State')
$ignored = @(git check-ignore -- $ignorePaths)
Set-ReportField 'GitIgnoredRuntime' ([pscustomobject]@{Requested=$ignorePaths;Ignored=$ignored;AllIgnored=($ignored.Count -eq $ignorePaths.Count)})
$secretFindings = @()
foreach ($file in Get-ChildItem $evidence -Recurse -File -Filter '*.json') {
    $text = Get-Content $file.FullName -Raw
    if ($text -match '(?i)"(password|passwd|token|secret|authorization|cookie|nro_dni|nroDni|email|direccion|apellido)"\s*:\s*"(?!\[REDACTADO\]|\*+)[^"\s][^"]*"') {
        $secretFindings += $file.Name
    }
}
Set-ReportField 'EvidenceSecurity' ([pscustomobject]@{JsonFilesScanned=@(Get-ChildItem $evidence -Recurse -File -Filter '*.json').Count;SensitiveValuesDetected=$secretFindings;NoSensitiveValuesDetected=($secretFindings.Count -eq 0);PersonalDataRedacted=$true;CompleteEnvOrConfigpropsResponsesSaved=$false;BrowserProfileIgnored=$true})
$integrityPath = Join-Path $runtime 'integridad-resultado.json'
if (Test-Path $integrityPath) { Set-ReportField 'Integrity' (Get-Content $integrityPath -Raw | ConvertFrom-Json) }
$imageAudit = @()
Add-Type -AssemblyName System.Drawing
foreach ($capture in $report.Screenshots.captures) {
    $file = Join-Path $evidence $capture.file
    $bitmap = New-Object Drawing.Bitmap($file)
    try {
        $bright=0
        for ($y=120; $y -lt 500; $y+=3) {
            for ($x=15; $x -lt 1450; $x+=3) {
                $pixel=$bitmap.GetPixel($x,$y)
                if ($pixel.R -gt 150 -and $pixel.G -gt 150 -and $pixel.B -gt 150) { $bright++ }
            }
        }
        $imageAudit += [pscustomobject]@{File=$capture.file;Width=$bitmap.Width;Height=$bitmap.Height;VisibleContent=($bright -ge 30);SHA256=(Get-FileHash $file -Algorithm SHA256).Hash}
    } finally { $bitmap.Dispose() }
}
Set-ReportField 'ScreenshotAudit' $imageAudit
$snapshotCounts = @()
foreach ($database in $databaseAfter) { foreach ($table in $database.tables) { $snapshotCounts += [pscustomobject]@{Database=$database.database;Table=$table.table;Rows=$table.rows} } }
Set-ReportField 'FinalRows' $snapshotCounts
Set-ReportField 'CompletedAt' (Get-Date).ToString('o')
Set-ReportField 'Step03' ([pscustomobject]@{ReadyForAuthorization=$true;Executed=$false;PrometheusRegistryAdded=$false;PrometheusInstalled=$false;GrafanaInstalled=$false})
$allChecks = $report.Completed -and $databaseSame -and $secretFindings.Count -eq 0 -and
    @($checks | Where-Object { !$_.SameProcess -or !$_.LocalhostOnly -or $_.Health -ne 'UP' }).Count -eq 0 -and
    @($audit | Where-Object { $_.DirectActuatorDeclarations -ne 1 -or $_.PrometheusLibraries -ne 0 }).Count -eq 0 -and
    @($resilience | Where-Object { $_.Kind -eq 'failed' -and $_.Count -ne 0 }).Count -eq 0 -and
    @($effective | Where-Object { !$_.Valid }).Count -eq 0 -and
    $imageAudit.Count -eq 18 -and @($imageAudit | Where-Object { !$_.VisibleContent }).Count -eq 0 -and
    $report.Integrity.IndexUnchanged -and $report.Integrity.Lab14Unchanged -and
    @($report.Integrity.ExternalChangedOrRemoved).Count -eq 0 -and @($report.Integrity.ExternalAdded).Count -eq 0 -and
    $report.GitIgnoredRuntime.AllIgnored
Set-ReportField 'FinalVerificationSuccessful' ([bool]$allChecks)
$report | ConvertTo-Json -Depth 60 | Set-Content $path -Encoding UTF8
[pscustomobject]@{Completed=$report.Completed;FinalVerificationSuccessful=$allChecks;RunningProcesses=$checks.Count;RealScreenshots=$report.Screenshots.captures.Count;DatabaseUnchanged=$databaseSame;SensitiveFindings=$secretFindings.Count}
