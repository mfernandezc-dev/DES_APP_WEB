$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Grafana.ps1')
$receipt=Join-Path $GrafRuntime 'instalacion.json'
if(!(Test-Path $receipt)) { throw 'No existe instalacion verificada de Grafana.' }
$installation=Get-Content $receipt -Raw | ConvertFrom-Json
$recordFile=Join-Path $GrafRuntime 'proceso.json'
if(Test-Path $recordFile) {
    $old=Get-Content $recordFile -Raw | ConvertFrom-Json
    if(Test-GrafanaIdentity $old) { Write-Host "Grafana propio ya esta activo: PID $($old.PID). No se duplica."; return }
    if(Get-Process -Id $old.PID -ErrorAction SilentlyContinue) { throw 'PID registrado ocupado por otra identidad; no se modifica.' }
}
if(@(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq 3000).Count) { throw '3000 ocupado; no se detiene ningun proceso.' }
if(@(Get-CimInstance Win32_Process | Where-Object { $_.Name -in @('grafana.exe','grafana-server.exe') }).Count) { throw 'Ya existe un proceso Grafana; revisar antes de iniciar otro.' }
if((Get-FileHash $installation.Executable -Algorithm SHA256).Hash -ne $installation.ExecutableSHA256) { throw 'Binario distinto de la instalacion verificada.' }
& (Join-Path $PSScriptRoot 'Acceso-Grafana.ps1') -Preparar
foreach($dir in @('data','logs','plugins','dashboards','provisioning\datasources','provisioning\dashboards')) { $null=New-Item -ItemType Directory (Join-Path $GrafRuntime $dir) -Force }
$source=Join-Path $GrafRoot 'observabilidad\grafana'
Copy-Item (Join-Path $source 'dashboards\lab15-observabilidad.json') (Join-Path $GrafRuntime 'dashboards\lab15-observabilidad.json')
Copy-Item (Join-Path $source 'provisioning\datasources\prometheus.yml') (Join-Path $GrafRuntime 'provisioning\datasources\prometheus.yml')
Copy-Item (Join-Path $source 'provisioning\dashboards\lab15.yml') (Join-Path $GrafRuntime 'provisioning\dashboards\lab15.yml')
$slash=$GrafRuntime.Replace('\','/')
$config=@"
[paths]
data = $slash/data
logs = $slash/logs
plugins = $slash/plugins
provisioning = $slash/provisioning
[server]
protocol = http
http_addr = 127.0.0.1
http_port = 3000
domain = localhost
root_url = http://localhost:3000/
enable_gzip = true
[database]
type = sqlite3
path = $slash/data/grafana.db
[security]
secret_key = `$__file{$slash/private/encryption.key}
cookie_secure = false
cookie_samesite = strict
disable_gravatar = true
allow_embedding = false
[auth.anonymous]
enabled = false
[users]
allow_sign_up = false
allow_org_create = false
default_theme = dark
[analytics]
reporting_enabled = false
check_for_updates = false
check_for_plugin_updates = false
feedback_links_enabled = false
[plugins]
plugin_admin_enabled = false
preinstall_disabled = true
public_key_retrieval_disabled = true
[news]
news_feed_enabled = false
[snapshots]
external_enabled = false
[dashboards]
min_refresh_interval = 5s
[unified_alerting]
enabled = false
[alerting]
enabled = false
[log]
mode = console file
level = info
"@
$configFile=Join-Path $GrafRuntime 'grafana-lab15.ini'
[IO.File]::WriteAllText($configFile,$config,(New-Object Text.UTF8Encoding($false)))
$id=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$stdout=Join-Path $GrafRuntime "logs\grafana-$id.stdout.log"
$stderr=Join-Path $GrafRuntime "logs\grafana-$id.stderr.log"
$arguments=@('server',"--homepath=$($installation.InstallDirectory)","--config=$configFile")
$prior=$env:LAB15_GRAFANA_DASHBOARDS
try {
    $env:LAB15_GRAFANA_DASHBOARDS=(Join-Path $GrafRuntime 'dashboards').Replace('\','/')
    $process=Start-Process $installation.Executable -ArgumentList @($arguments | ForEach-Object { '"'+$_+'"' }) -WorkingDirectory $GrafRuntime -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
} finally { $env:LAB15_GRAFANA_DASHBOARDS=$prior }
$null=$process.Handle
$record=[pscustomobject]@{PID=$process.Id;StartTimeUtc=$process.StartTime.ToUniversalTime().ToString('o');Executable=$installation.Executable;ExecutableSHA256=$installation.ExecutableSHA256;Arguments=$arguments;Runtime=$GrafRuntime;Version=$installation.Version;Port=3000;ListenAddress='127.0.0.1:3000';ConfigFile=$configFile;ConfigSHA256=(Get-FileHash $configFile -Algorithm SHA256).Hash;Stdout=$stdout;Stderr=$stderr;Ready=$false}
$record | ConvertTo-Json -Depth 8 | Set-Content $recordFile -Encoding UTF8
$deadline=[DateTime]::UtcNow.AddSeconds(180)
do {
    if($process.HasExited) { throw 'Grafana termino durante inicio; revisar logs propios sin reiniciar otros servicios.' }
    try { $health=Invoke-RestMethod 'http://127.0.0.1:3000/api/health' -TimeoutSec 5;$record.Ready=$health.database -eq 'ok' } catch { $record.Ready=$false }
    if(!$record.Ready) { Start-Sleep -Seconds 2 }
} while(!$record.Ready -and [DateTime]::UtcNow -lt $deadline)
if(!$record.Ready) { throw 'Grafana no alcanzo ready; conservar proceso y diagnosticar.' }
$listeners=@(Get-NetTCPConnection -State Listen | Where-Object OwningProcess -eq $process.Id)
if($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1' -or $listeners[0].LocalPort -ne 3000) { throw 'Listener de Grafana no coincide con localhost:3000.' }
$record | ConvertTo-Json -Depth 8 | Set-Content $recordFile -Encoding UTF8
[pscustomobject]@{Phase='C-D';Completed=$true;Timestamp=(Get-Date).ToString('o');PID=$record.PID;Ready=$true} | ConvertTo-Json | Set-Content (Join-Path $GrafStep 'checkpoint-CD.json') -Encoding UTF8
Write-Host "Grafana $($record.Version) listo en 127.0.0.1:3000; PID=$($record.PID). Completar cambio inicial de clave antes de publicar evidencia."
