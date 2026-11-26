$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Prometheus.ps1')
$listeners=@(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq 9090)
if($listeners.Count) { throw "9090 ocupado por PID $($listeners[0].OwningProcess). No se detiene ningun proceso." }
if(@(Get-CimInstance Win32_Process -Filter "name='prometheus.exe'").Count) { throw 'Ya existe un proceso Prometheus; no se crea otro automaticamente.' }
if((Get-FileHash $PromExecutable -Algorithm SHA256).Hash -ne $PromInstallation.PrometheusExecutableSHA256) { throw 'El ejecutable no coincide con el paquete verificado.' }
$validation=Test-PromConfig
Write-Host $validation.Output
$helpFile=Join-Path $PromRuntime 'prometheus-help.txt'
$helpProcess=Start-Process $PromExecutable -ArgumentList '--help' -PassThru -WindowStyle Hidden -RedirectStandardOutput $helpFile -RedirectStandardError (Join-Path $PromRuntime 'prometheus-help.stderr.log')
$null=$helpProcess.Handle;$helpProcess.WaitForExit();$helpProcess.WaitForExit()
$helpText=[IO.File]::ReadAllText($helpFile)+[IO.File]::ReadAllText((Join-Path $PromRuntime 'prometheus-help.stderr.log'))
if($helpText -notmatch 'storage\.tsdb\.retention\.time') { throw 'La version no confirma soporte del argumento de retencion solicitado.' }
$data=Join-Path $PromRuntime 'data'
$null=New-Item -ItemType Directory $data -Force
$arguments=@("--config.file=$PromConfig",'--web.listen-address=127.0.0.1:9090',"--storage.tsdb.path=$data",'--storage.tsdb.retention.time=1d')
$quoted=@($arguments | ForEach-Object { '"'+$_+'"' })
$id=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$stdout=Join-Path $PromRuntime "prometheus-$id.stdout.log"
$stderr=Join-Path $PromRuntime "prometheus-$id.stderr.log"
$process=Start-Process $PromExecutable -ArgumentList $quoted -WorkingDirectory $PromLabRoot -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null=$process.Handle
$record=[pscustomobject]@{PID=$process.Id;StartTimeUtc=$process.StartTime.ToUniversalTime().ToString('o');Executable=$PromExecutable;ExecutableSHA256=$PromInstallation.PrometheusExecutableSHA256;Version=$PromInstallation.Version;Port=9090;ListenAddress='127.0.0.1:9090';Arguments=$arguments;ConfigFile=$PromConfig;ConfigSHA256=$validation.ConfigSHA256;DataPath=$data;Retention='1d';Stdout=$stdout;Stderr=$stderr;Ready=$false;AdminApiEnabled=$false;LifecycleEnabled=$false}
$record | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $PromRuntime 'proceso.json') -Encoding UTF8
try {
    $deadline=[DateTime]::UtcNow.AddSeconds(120)
    do {
        if($process.HasExited) { throw 'Prometheus termino prematuramente; revisar logs propios.' }
        try { $response=Invoke-WebRequest 'http://localhost:9090/-/ready' -UseBasicParsing -TimeoutSec 5; $record.Ready=$response.StatusCode -eq 200 } catch { $record.Ready=$false }
        if(!$record.Ready) { Start-Sleep -Seconds 2 }
    } while(!$record.Ready -and [DateTime]::UtcNow -lt $deadline)
    if(!$record.Ready) { throw 'Prometheus no alcanzo ready dentro del plazo.' }
    $ownListeners=@(Get-NetTCPConnection -State Listen | Where-Object OwningProcess -eq $process.Id)
    if($ownListeners.Count -ne 1 -or $ownListeners[0].LocalAddress -ne '127.0.0.1' -or $ownListeners[0].LocalPort -ne 9090) { throw 'Prometheus no esta limitado al listener local esperado.' }
    $record | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $PromRuntime 'proceso.json') -Encoding UTF8
    Write-Host "Prometheus $($record.Version) listo; PID=$($record.PID); 127.0.0.1:9090; TSDB local; retencion 1d."
} catch {
    if(!$process.HasExited -and $process.StartTime.ToUniversalTime().ToString('o') -eq $record.StartTimeUtc) { Stop-Process -Id $process.Id }
    throw
}
