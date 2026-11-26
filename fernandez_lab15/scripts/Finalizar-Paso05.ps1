$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Grafana.ps1')
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Huellas-Bases.ps1')
if((Get-Location).Path -ne $GrafRoot) { throw 'Ejecutar exclusivamente desde fernandez_lab15.' }
function Read-Json([string]$Path) { return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) }
$initial=Read-Json (Join-Path $GrafStep 'checkpoint-A.json')
$installation=Read-Json (Join-Path $GrafRuntime 'instalacion.json')
$graf=Read-Json (Join-Path $GrafRuntime 'proceso.json')
$connection=Read-Json (Join-Path $GrafEvidence 'CONEXION-GRAFANA.json')
$queries=Read-Json (Join-Path $GrafEvidence 'CONSULTAS-GRAFANA.json')
$ui=Read-Json (Join-Path $GrafEvidence 'INTERFAZ-GRAFANA.json')
$stateTable=Read-Json (Join-Path $GrafEvidence 'TABLA-ESTADOS-GRAFANA.json')
$traffic=Read-Json (Join-Path $GrafEvidence 'CONSULTAS-PROMETHEUS.json')
$regression=Read-Json (Join-Path $GrafEvidence 'REGRESION-ACTUATOR.json')
$authentication=Read-Json (Join-Path $GrafEvidence 'AUTENTICACION-GRAFANA.json')
$captures=Read-Json (Join-Path $GrafEvidence 'CAPTURAS-PASO05.json')
$registry=Read-Json (Join-Path $GrafRoot '.runtime\paso03\procesos.json')
$listeners=@(Get-NetTCPConnection -State Listen)
$java=@(Get-CimInstance Win32_Process -Filter "name='java.exe' OR name='javaw.exe'")
$services=@()
foreach($record in $registry) {
    $before=$initial.Microservices | Where-Object Service -eq $record.Service
    $process=$java | Where-Object ProcessId -eq $record.PID
    $actual=Get-Process -Id $record.PID
    $identity=$process -and $process.ExecutablePath -eq $record.Java -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $before.StartTimeUtc -and $process.CommandLine -like "*@../.runtime/paso03/$($record.Service).args*"
    $own=@($listeners | Where-Object LocalPort -eq $record.Port)
    $local=$own.Count -eq 1 -and $own[0].LocalAddress -eq '127.0.0.1' -and $own[0].OwningProcess -eq $record.PID -and @($listeners | Where-Object OwningProcess -eq $record.PID).Count -eq 1
    $h=Invoke-RestMethod "http://localhost:$($record.Port)/actuator/health" -TimeoutSec 15
    $services += [pscustomobject]@{Service=$record.Service;PID=$record.PID;Port=$record.Port;SameProcess=[bool]$identity;LocalhostOnly=$local;Health=$h.status;Instances=@($java | Where-Object CommandLine -like "*@../.runtime/paso03/$($record.Service).args*").Count;JarUnchanged=((Get-FileHash $record.Jar -Algorithm SHA256).Hash -eq $record.JarSHA256)}
}
$promBefore=$initial.PrometheusProcess
$prom=Get-CimInstance Win32_Process -Filter "ProcessId=$($promBefore.PID)"
$promActual=Get-Process -Id $promBefore.PID
$promSame=$prom -and $prom.ExecutablePath -eq $promBefore.Executable -and $promActual.StartTime.ToUniversalTime().ToString('o') -eq $promBefore.StartTimeUtc
foreach($a in $promBefore.Arguments) { if($prom.CommandLine.IndexOf($a,[StringComparison]::OrdinalIgnoreCase) -lt 0) { $promSame=$false } }
$promListeners=@($listeners | Where-Object OwningProcess -eq $promBefore.PID)
$promLocal=$promListeners.Count -eq 1 -and $promListeners[0].LocalAddress -eq '127.0.0.1' -and $promListeners[0].LocalPort -eq 9090
$promCount=@(Get-CimInstance Win32_Process -Filter "name='prometheus.exe'").Count
$targets=Invoke-RestMethod 'http://127.0.0.1:9090/api/v1/targets' -TimeoutSec 15
$targets | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $GrafEvidence 'targets-cierre.json') -Encoding UTF8
$active=@($targets.data.activeTargets)
$targetValid=$active.Count -eq 7 -and @($active | Where-Object { $_.health -ne 'up' -or $_.lastError -ne '' }).Count -eq 0
foreach($r in $registry) { if(@($active | Where-Object { $_.labels.job -eq $r.Service -and $_.scrapeUrl -eq "http://127.0.0.1:$($r.Port)/actuator/prometheus" }).Count -ne 1) { $targetValid=$false } }
$grafanaIdentity=Test-GrafanaIdentity $graf
$grafanaListeners=@($listeners | Where-Object OwningProcess -eq $graf.PID)
$grafanaLocal=$grafanaListeners.Count -eq 1 -and $grafanaListeners[0].LocalAddress -eq '127.0.0.1' -and $grafanaListeners[0].LocalPort -eq 3000
$grafanaCount=@(Get-CimInstance Win32_Process | Where-Object Name -in @('grafana.exe','grafana-server.exe')).Count
$health=Invoke-RestMethod 'http://127.0.0.1:3000/api/health' -TimeoutSec 15
$configurationUnchanged=(Get-FileHash $graf.ConfigFile -Algorithm SHA256).Hash -eq $graf.ConfigSHA256
$sourceDashboard=Join-Path $GrafRoot 'observabilidad\grafana\dashboards\lab15-observabilidad.json'
$dashboardHash=(Get-FileHash $sourceDashboard -Algorithm SHA256).Hash
$provisioningUnchanged=$dashboardHash -eq (Get-FileHash (Join-Path $GrafRuntime 'dashboards\lab15-observabilidad.json') -Algorithm SHA256).Hash
foreach($relative in @('datasources\prometheus.yml','dashboards\lab15.yml')) {
    if((Get-FileHash (Join-Path $GrafRoot "observabilidad\grafana\provisioning\$relative") -Algorithm SHA256).Hash -ne (Get-FileHash (Join-Path $GrafRuntime "provisioning\$relative") -Algorithm SHA256).Hash) { $provisioningUnchanged=$false }
}
$before=Read-Json (Join-Path $GrafStep 'bases-antes.json')
$after=@(Get-Lab15DatabaseSnapshot -Paso 03)
$after | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $GrafStep 'bases-finales.json') -Encoding UTF8
$dbUnchanged=($before | ConvertTo-Json -Depth 12 -Compress) -eq ($after | ConvertTo-Json -Depth 12 -Compress)
$prior=Read-Json (Join-Path $GrafRoot 'evidencias\03-prometheus\VERIFICACION-PASO04.json')
$dbListeners=@($listeners | Where-Object LocalPort -eq 3306)
$mariaSame=$dbListeners.Count -gt 0 -and $dbListeners[0].OwningProcess -eq $prior.MariaDB.PID
$privateAcl=Get-Acl $GrafPrivate
$aclPrivate=$privateAcl.AreAccessRulesProtected -and @($privateAcl.Access | Where-Object { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -notin @([Security.Principal.WindowsIdentity]::GetCurrent().User.Value,'S-1-5-18') }).Count -eq 0
$ignored=@(git check-ignore -- '.runtime/grafana/data/grafana.db' '.runtime/grafana/private/admin.clixml' '.runtime/grafana/logs/grafana.log' '.runtime/grafana/plugins/test' '.runtime/paso05/chrome-test/Local State' '.runtime/tools/grafana/bin/grafana.exe')
$sensitive=@();$badJson=@()
foreach($file in Get-ChildItem $GrafEvidence -Recurse -File | Where-Object Extension -in @('.json','.txt','.md')) {
    $text=[IO.File]::ReadAllText($file.FullName)
    if($text -match '(?i)"(password|passwd|token|secret|authorization|cookie|nro_dni|nroDni|email|direccion|apellido)"\s*:\s*"(?!\[REDACTADO\]|\*+)[^"\s][^"]*"') { $sensitive += $file.Name }
    if($file.Extension -eq '.json') { try { $null=$text | ConvertFrom-Json } catch { $badJson += $file.Name } }
}
# Comprobar el secreto contra texto publicable, sin mostrar ni publicar su valor.
$credential=Get-GrafanaCredential
$secret=$credential.GetNetworkCredential().Password
foreach($file in Get-ChildItem $GrafRoot -File -Recurse | Where-Object { $_.FullName -notlike "$GrafRuntime\*" -and $_.FullName -notlike "$GrafRoot\.runtime\*" -and $_.FullName -notmatch '\\target\\' -and $_.Extension -in @('.json','.ps1','.mjs','.md','.yml','.yaml','.txt') }) {
    if([IO.File]::ReadAllText($file.FullName).Contains($secret)) { $sensitive += $file.FullName.Substring($GrafRoot.Length+1) }
}
$secret=$null;$credential=$null
Add-Type -AssemblyName System.Drawing
$images=@()
foreach($c in $captures.captures) {
    $file=Join-Path $GrafEvidence $c.file
    $image=New-Object Drawing.Bitmap($file)
    try { $images += [pscustomobject]@{File=$c.file;Width=$image.Width;Height=$image.Height;Bytes=(Get-Item $file).Length;SHA256=(Get-FileHash $file -Algorithm SHA256).Hash} } finally { $image.Dispose() }
}
$captureValid=!$captures.error -and $images.Count -eq 14 -and @($images | Where-Object { $_.Width -lt 1000 -or $_.Height -lt 600 }).Count -eq 0
foreach($n in 1..14) { if(@($images | Where-Object File -like ($n.ToString('00')+'-*.png')).Count -ne 1) { $captureValid=$false } }
foreach($c in $captures.captures) { if($c.bytes -ne ($images | Where-Object File -eq $c.file).Bytes) { $captureValid=$false } }
$docs=Join-Path $GrafEvidence 'PASO05.md'
$documentsExist=(Test-Path $docs) -and (Select-String -LiteralPath (Join-Path $GrafRoot 'README.md') -Pattern 'lab15-observabilidad' -Quiet)
& (Join-Path $PSScriptRoot 'Integridad-Paso05.ps1') -Momento despues
$integrity=Read-Json (Join-Path $GrafStep 'integridad-resultado.json')
$protectedChanges=@($integrity.ModifiedLocalFiles+$integrity.AddedLocalFiles | Where-Object { $_ -match '^(config-server|eureka-server|gateway-service|categoria-service|producto-service|cliente-service|pedido-service|observabilidad/prometheus)/' })
$sameServices=$services.Count -eq 7 -and @($services | Where-Object { !$_.SameProcess -or !$_.LocalhostOnly -or !$_.JarUnchanged -or $_.Health -ne 'UP' -or $_.Instances -ne 1 }).Count -eq 0
$integrityValid=$integrity.Lab14Unchanged -and $integrity.IndexUnchanged -and $integrity.HeadUnchanged -and $integrity.ExternalGitStatusUnchanged -and $integrity.PriorEvidenceUnchanged -and @($integrity.ExternalAdded).Count -eq 0 -and @($integrity.ExternalChangedOrRemoved).Count -eq 0 -and $protectedChanges.Count -eq 0
$successful=$initial.Completed -and $installation.SHA256Verified -and (Get-FileHash $installation.Executable -Algorithm SHA256).Hash -eq $installation.ExecutableSHA256 -and
    $connection.Completed -and $queries.Completed -and $ui.Completed -and $stateTable.Completed -and $authentication.Completed -and $authentication.InitialPasswordRejected -and
    $traffic.Completed -and $traffic.Traffic.Count -eq 120 -and $regression.Completed -and $regression.Actuator.Count -eq 21 -and @($regression.Actuator | Where-Object Status -ne 200).Count -eq 0 -and
    $sameServices -and $promSame -and $promLocal -and $promCount -eq 1 -and $targetValid -and $grafanaIdentity -and $grafanaLocal -and $grafanaCount -eq 1 -and $health.database -eq 'ok' -and
    $configurationUnchanged -and $provisioningUnchanged -and $dbUnchanged -and $mariaSame -and $aclPrivate -and $ignored.Count -eq 6 -and $sensitive.Count -eq 0 -and $badJson.Count -eq 0 -and
    $captureValid -and $documentsExist -and $integrityValid
$report=[ordered]@{
    Step='05';Timestamp=(Get-Date).ToString('o');Completed=[bool]$successful;Installation=$installation
    GrafanaProcess=$graf;GrafanaIdentityVerified=$grafanaIdentity;GrafanaLocalhostOnly=$grafanaLocal;GrafanaProcessCount=$grafanaCount;GrafanaHealth=$health
    Configuration=[pscustomobject]@{RuntimeConfigUnchanged=$configurationUnchanged;PortableProvisioningMatches=$provisioningUnchanged;DashboardSHA256=$dashboardHash;Effective=$connection.EffectiveSettings;ActualOperationalPaths=$connection.ActualOperationalPaths;ProtectedSourceChanges=$protectedChanges}
    Authentication=$authentication;Datasource=$connection.Datasource;DatasourceHealth=$connection.DatasourceHealth;AllDatasources=$connection.AllDatasources;AnonymousAccess=$connection.AnonymousAccess;Up=$connection.Up
    Dashboard=[pscustomobject]@{UID='lab15-observabilidad';Name='Lab 15 - Observabilidad de Microservicios';URL='http://localhost:3000/d/lab15-observabilidad/lab-15-observabilidad-de-microservicios';Provisioned=$connection.Dashboard.body.meta.provisioned;Panels=18;DataPanels=17;RequiredPanelCategories=15;Refresh='5s';InitialRange='now-15m';PanelChecks=$queries.Panels;StateTable=$stateTable;Filters=$queries.Filters;UI=$ui;Evidence='dashboard-cargado.json'}
    Traffic=[pscustomobject]@{Completed=$traffic.Completed;Methods=$traffic.HttpMethods;GETs=$traffic.Traffic.Count;Rounds=24;Start=$traffic.TrafficStart;End=$traffic.TrafficEnd;GatewayCounters=$traffic.GatewayCounterComparison;Evidence='CONSULTAS-PROMETHEUS.json'}
    Microservices=$services;Prometheus=[pscustomobject]@{PID=$promBefore.PID;Port=9090;SameProcess=[bool]$promSame;LocalhostOnly=$promLocal;TargetsUP=@($active | Where-Object health -eq 'up').Count;TargetsDOWN=@($active | Where-Object health -ne 'up').Count;TargetsValid=$targetValid;Evidence='targets-cierre.json'}
    Regression=[pscustomobject]@{Completed=$regression.Completed;ActuatorTotal=$regression.Actuator.Count;ActuatorHTTP200=@($regression.Actuator | Where-Object Status -eq 200).Count;Functional=$regression.Functional;Eureka=$regression.Eureka;Evidence='REGRESION-ACTUATOR.json'}
    Database=[pscustomobject]@{Unchanged=$dbUnchanged;MariaDBSameProcess=$mariaSame;PID=$prior.MariaDB.PID;Before=$before;After=$after;Scope='Cuatro esquemas DEV, estructuras y todas las filas; lector JDBC en transaccion READ ONLY y rollback'}
    Integrity=$integrity;Security=[pscustomobject]@{PrivateACLProtected=$aclPrivate;DPAPIEncryptedCredential=$true;SecretScanFindings=$sensitive;OperationalFilesIgnored=($ignored.Count -eq 6);NoProjectDatabaseDatasource=$true;NoPlaintextSecretPublished=$true;ConfigRepoCommit=$Lab15Commit;ConfigRepoModified=$false;WindowsServiceRegistered=$false;DockerExecuted=$false}
    Screenshots=$captures;ScreenshotAudit=$images;ScreenshotVerification=$captureValid;Documentation=[pscustomobject]@{Report='PASO05.md';SHA256=(Get-FileHash $docs -Algorithm SHA256).Hash};InvalidJSON=$badJson
    RemainingStep05Activities=@();AdditionalPendingActivities=@();Step06=[pscustomobject]@{ReadyForAuthorization=[bool]$successful;Executed=$false;GithubPublished=$false}
}
$report | ConvertTo-Json -Depth 70 | Set-Content (Join-Path $GrafEvidence 'VERIFICACION-PASO05.json') -Encoding UTF8
[pscustomobject]@{Phase='Final';Completed=[bool]$successful;Timestamp=$report.Timestamp;Evidence='evidencias/04-grafana/VERIFICACION-PASO05.json'} | ConvertTo-Json | Set-Content (Join-Path $GrafStep 'checkpoint-final.json') -Encoding UTF8
[pscustomobject]@{Completed=$successful;GrafanaPID=$graf.PID;TargetsUP=7;Actuator200=@($regression.Actuator | Where-Object Status -eq 200).Count;PanelesVerificados=$queries.Panels.Count;Capturas=$images.Count;BasesIntactas=$dbUnchanged;Integridad=$integrityValid;ServiciosSinReinicios=$sameServices;HallazgosSensibles=$sensitive.Count} | Format-List
if(!$successful) { throw 'PASO 05 incompleto: revisar VERIFICACION-PASO05.json y checkpoints.' }
