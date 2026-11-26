# Inicio secuencial del conjunto real. No ejecuta pruebas Maven ni escrituras HTTP.
param([ValidateSet('02','03')][string]$Paso = '03',[switch]$ReutilizarActivos)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Huellas-Bases.ps1')
Assert-NoLab14Process
if(!$ReutilizarActivos) { foreach ($port in $Lab15Ports.Values) { Assert-Lab15PortFree $port } }
$db = @(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq 3306)
if (!$db.Count) { throw 'MariaDB no esta escuchando en 3306. No se inicia ni modifica XAMPP automaticamente.' }
$dbProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$($db[0].OwningProcess)"
if ($dbProcess.ExecutablePath -notlike '*\xampp\mysql\bin\mysqld.exe') { throw 'El puerto 3306 no pertenece al MariaDB XAMPP esperado.' }
$runtime = Join-Path $Lab15Root ".runtime\paso$Paso"
$null = New-Item -ItemType Directory $runtime -Force
$java = Join-Path $Lab15JavaHome 'bin\java.exe'
if(!(Test-Path (Join-Path $runtime 'VerificarContexto.class')) -or !(Test-Path (Join-Path $runtime 'ResumenBases.class'))) {
    & (Join-Path $Lab15JavaHome 'bin\javac.exe') '-d' $runtime (Join-Path $PSScriptRoot 'VerificarContexto.java') (Join-Path $PSScriptRoot 'ResumenBases.java')
    if ($LASTEXITCODE -ne 0) { throw 'Fallo al compilar las sondas de lectura.' }
}
$order = @('config-server','eureka-server','categoria-service','producto-service','cliente-service','pedido-service','gateway-service')
$records = @()
$registry = Join-Path $runtime 'procesos.json'
$created=@()
if($ReutilizarActivos -and (Test-Path $registry)) { $records=@((Get-Content $registry -Raw | ConvertFrom-Json) | ForEach-Object { $_ }) }
try {
    foreach ($service in $order) {
        if($ReutilizarActivos) {
            $previous=$records | Where-Object Service -eq $service
            $listeners=@(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq $Lab15Ports[$service])
            if($listeners.Count) {
                if(!$previous) { throw "$service ocupa un puerto sin registro propio; no se modifica." }
                $existing=Get-CimInstance Win32_Process -Filter "ProcessId=$($previous.PID)"
                $actual=Get-Process -Id $previous.PID -ErrorAction Stop
                $same=$existing -and $existing.ExecutablePath -eq $java -and $existing.CommandLine -like "*@../.runtime/paso$Paso/$service.args*" -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $previous.StartTimeUtc -and $listeners.Count -eq 1 -and $listeners[0].OwningProcess -eq $previous.PID -and $listeners[0].LocalAddress -eq '127.0.0.1'
                if(!$same -or (Get-FileHash $previous.Jar -Algorithm SHA256).Hash -ne $previous.JarSHA256) { throw "$service tiene identidad o artefacto distintos; no se reinicia." }
                $health=Invoke-RestMethod "http://localhost:$($previous.Port)/actuator/health" -TimeoutSec 15
                if($health.status -ne 'UP') { throw "$service no esta saludable; diagnosticar sin reinicio automatico." }
                Write-Host "$service : reutilizado PID=$($previous.PID), UP";continue
            }
            if($previous -and (Get-Process -Id $previous.PID -ErrorAction SilentlyContinue)) { throw "$service tiene PID vivo sin listener esperado; no se duplica." }
            if(@(Get-CimInstance Win32_Process -Filter "name='java.exe' OR name='javaw.exe'" | Where-Object CommandLine -like "*@../.runtime/paso$Paso/$service.args*").Count) { throw "$service ya tiene un proceso propio; no se duplica." }
        }
        Assert-Lab15PortFree $Lab15Ports[$service]
        $jar = Join-Path $Lab15Root "$service\target\$service-0.0.1-SNAPSHOT.jar"
        if (!(Test-Path $jar)) { throw "Falta compilar $service." }
        $jarHash = (Get-FileHash $jar -Algorithm SHA256).Hash
        if ($Paso -eq '03') {
            $builds = Get-Content (Join-Path $runtime 'compilacion-todos.json') -Raw | ConvertFrom-Json
            $build = $builds | Where-Object Service -eq $service
            if (!$build.Success -or $build.JarSHA256 -ne $jarHash) { throw 'El artefacto no coincide con la compilacion aprobada de PASO 03.' }
        }
        if ($service -in $Lab15Business) {
            $config = Invoke-RestMethod "http://localhost:8888/$service/dev/$Lab15Commit" -TimeoutSec 30
            if ($config.version -ne $Lab15Commit) { throw 'Config Server no devolvio el commit autorizado.' }
            if (!@($config.propertySources | Where-Object name -like '*github.com/mfernandezc-dev/config-repo*').Count) {
                throw 'La configuracion no procede del repositorio esperado.'
            }
        }
        $main = switch ($service) {
            'config-server' { 'com.tecsup.ConfigServerApplication' }
            'eureka-server' { 'com.tecsup.eureka.EurekaServerApplication' }
            'gateway-service' { 'com.tecsup.GatewayServiceApplication' }
            'categoria-service' { 'com.tecsup.CategoriaServiceApplication' }
            'producto-service' { 'com.tecsup.ProductoServiceApplication' }
            'cliente-service' { 'com.tecsup.ClienteServiceApplication' }
            'pedido-service' { 'com.tecsup.PedidoServiceApplication' }
        }
        $lines = @('-Xms64m','-Xmx384m','-Dspring.devtools.restart.enabled=false',
            "-Dloader.path=../.runtime/paso$Paso",'-Dloader.main=VerificarContexto',
            '-cp',"target/$service-0.0.1-SNAPSHOT.jar",'org.springframework.boot.loader.launch.PropertiesLauncher',
            $main) + @(Get-Lab15Arguments $service) + @('--lab15.probe.keep-alive=true')
        $argsFile = Join-Path $runtime "$service.args"
        $quoted = @($lines | ForEach-Object { '"' + $_.Replace('\','\\').Replace('"','\"') + '"' })
        [IO.File]::WriteAllLines($argsFile, $quoted, (New-Object Text.UTF8Encoding($false)))
        $id = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $stdout = Join-Path $runtime "$service-$id.stdout.log"
        $stderr = Join-Path $runtime "$service-$id.stderr.log"
        $process = Start-Process $java -ArgumentList "@../.runtime/paso$Paso/$service.args" -WorkingDirectory (Join-Path $Lab15Root $service) -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $null = $process.Handle
        $record = [pscustomobject]@{Service=$service; PID=$process.Id; Port=$Lab15Ports[$service]; StartTimeUtc=$process.StartTime.ToUniversalTime().ToString('o'); Java=$java; ArgsFile=$argsFile; Jar=$jar; JarSHA256=$jarHash; Stdout=$stdout; Stderr=$stderr; Ready=$false}
        $records = @($records | Where-Object Service -ne $service) + @($record)
        $created += $record
        $records | ConvertTo-Json -Depth 5 | Set-Content $registry -Encoding UTF8
        $deadline = [DateTime]::UtcNow.AddSeconds(180)
        do {
            if ($process.HasExited) { throw "$service termino prematuramente. Revise sus logs operativos." }
            $line = Get-Content $stdout | Where-Object { $_.StartsWith('LAB15_RESULT ') } | Select-Object -Last 1
            if ($line) {
                $result = $line.Substring('LAB15_RESULT '.Length) | ConvertFrom-Json
                if (!$result.valid) { throw "La configuracion efectiva de $service no es segura." }
                try {
                    $response = Invoke-WebRequest "http://localhost:$($record.Port)/actuator" -UseBasicParsing -TimeoutSec 5
                    $record.Ready = $response.StatusCode -eq 200
                } catch { $record.Ready = $false }
            }
            if (!$record.Ready) { Start-Sleep -Seconds 2 }
        } while (!$record.Ready -and [DateTime]::UtcNow -lt $deadline)
        if (!$record.Ready) { throw "Tiempo agotado esperando $service." }
        $result | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $runtime "proteccion-$service.json") -Encoding UTF8
        $records | ConvertTo-Json -Depth 5 | Set-Content $registry -Encoding UTF8
        Write-Host "$service : listo; PID=$($record.PID); puerto=$($record.Port); configuracion efectiva validada"
        if ($service -eq 'config-server') {
            @(Get-Lab15DatabaseSnapshot -Paso $Paso) | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $runtime 'bases-antes.json') -Encoding UTF8
        }
    }
} catch {
    Write-Warning 'Inicio incompleto. Se detienen exclusivamente los procesos creados por esta invocacion.'
    foreach ($record in $created) {
        $owned = Get-CimInstance Win32_Process -Filter "ProcessId=$($record.PID)"
        if ($owned -and $owned.CommandLine -like "*@../.runtime/paso$Paso/$($record.Service).args*") {
            $actual = Get-Process -Id $record.PID -ErrorAction SilentlyContinue
            if ($actual -and $actual.StartTime.ToUniversalTime().ToString('o') -eq $record.StartTimeUtc) { Stop-Process -Id $record.PID }
        }
    }
    throw
}
Write-Host "Siete procesos independientes conservados en segundo plano. Registro: .runtime/paso$Paso/procesos.json"
