# Ejecutar solo para la preparacion: Config Server + UN cliente cada vez.
# No inicia Eureka/Gateway ni llama a endpoints de negocio ni ejecuta pruebas Maven.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
Assert-NoLab14Process
foreach ($port in $Lab15Ports.Values) { Assert-Lab15PortFree $port }
$runtime = Join-Path $Lab15Root '.runtime'
$diagnostics = Join-Path $runtime 'diagnostico'
$null = New-Item -ItemType Directory $diagnostics -Force
$runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$previous = Join-Path $diagnostics 'verificacion-base.json'
if (Test-Path $previous) {
    $history = Join-Path $diagnostics ('verificacion-anterior-' + [Guid]::NewGuid().ToString('N') + '.json')
    Copy-Item $previous $history
}
$java = Join-Path $Lab15JavaHome 'bin\java.exe'
$javac = Join-Path $Lab15JavaHome 'bin\javac.exe'
& $javac '-d' $diagnostics (Join-Path $PSScriptRoot 'VerificarContexto.java') (Join-Path $PSScriptRoot 'ResumenBases.java')
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron compilar las sondas de lectura.' }

function New-ProbeArguments([string]$Service, [string]$Main) {
    $lines = @(
        '-Dspring.devtools.restart.enabled=false',
        '-Dloader.path=../.runtime/diagnostico',
        '-Dloader.main=VerificarContexto',
        '-cp',
        "target/$Service-0.0.1-SNAPSHOT.jar",
        'org.springframework.boot.loader.launch.PropertiesLauncher',
        $Main
    ) + @(Get-Lab15Arguments $Service) + @('--server.address=127.0.0.1','--spring.main.banner-mode=off')
    if ($Service -eq 'config-server') {
        $lines += '--lab15.probe.hold=true'
    } else {
        # Aislamiento de la comprobacion, no cambio permanente de Eureka.
        $lines += @('--eureka.client.enabled=false','--spring.cloud.discovery.enabled=false',
            '--spring.datasource.hikari.read-only=true',
            '"--spring.datasource.hikari.connection-init-sql=SET SESSION TRANSACTION READ ONLY"')
    }
    $file = Join-Path $diagnostics "$Service.args"
    [IO.File]::WriteAllLines($file, $lines, (New-Object Text.UTF8Encoding($false)))
    return "@../.runtime/diagnostico/$Service.args"
}

function Get-ReadOnlySnapshot($Configurations) {
    $driver = Join-Path $env:USERPROFILE '.m2\repository\com\mysql\mysql-connector-j\9.7.0\mysql-connector-j-9.7.0.jar'
    if (!(Test-Path $driver)) { throw 'No se encontro el driver JDBC original en la cache Maven.' }
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $java
    $info.WorkingDirectory = $Lab15Root
    $info.Arguments = '-cp ".runtime/diagnostico;' + $driver + '" ResumenBases'
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    $null = $process.Start()
    foreach ($service in $Lab15Business) {
        $values = $Configurations[$service]
        foreach ($value in @($service, $values['spring.datasource.url'], $values['spring.datasource.username'], $values['spring.datasource.password'])) {
            $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$value))
            $process.StandardInput.WriteLine($encoded)
        }
    }
    $process.StandardInput.Close()
    $output = $process.StandardOutput.ReadToEnd()
    $errorOutput = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        $safeError = ($errorOutput -split "`n" | Where-Object { $_ -match '^SQL_READ_ONLY_SNAPSHOT_FAILED: [A-Za-z]+ phase=[a-z:-]+ state=[A-Za-z0-9]+ code=[0-9]+\s*$' }) -join '; '
        throw "La lectura SQL protegida fallo. $safeError"
    }
    return ($output | ConvertFrom-Json)
}

$server = $null
$client = $null
$report = [ordered]@{ Commit=$Lab15Commit; Java='26.0.2.1'; MavenTestsExecuted=$false; BusinessRequestsSent=0; Configurations=@(); Clients=@(); DatabaseUnchanged=$false; Completed=$false }
try {
    $serverArg = New-ProbeArguments 'config-server' 'com.tecsup.ConfigServerApplication'
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $java
    $start.Arguments = $serverArg
    $start.WorkingDirectory = Join-Path $Lab15Root 'config-server'
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $false
    $start.RedirectStandardError = $false
    $server = New-Object Diagnostics.Process
    $server.StartInfo = $start
    $null = $server.Start()
    $deadline = [DateTime]::UtcNow.AddSeconds(120)
    $ready = $false
    do {
        if ($server.HasExited) { throw 'Config Server termino antes de estar listo.' }
        try {
            $response = Invoke-RestMethod 'http://localhost:8888/categoria-service/dev' -TimeoutSec 15
            $ready = $response.version -eq $Lab15Commit
        } catch { $ready = $false }
        if (!$ready) { Start-Sleep -Seconds 2 }
    } while (!$ready -and [DateTime]::UtcNow -lt $deadline)
    if (!$ready) { throw 'Config Server no devolvio el commit fijo dentro del plazo.' }

    $configurations = @{}
    foreach ($service in $Lab15Business) {
        $default = Invoke-RestMethod "http://localhost:8888/$service/dev" -TimeoutSec 30
        $fixed = Invoke-RestMethod "http://localhost:8888/$service/dev/$Lab15Commit" -TimeoutSec 30
        if ($default.version -ne $Lab15Commit -or $fixed.version -ne $Lab15Commit) { throw 'Referencia remota inesperada.' }
        $values = @{}
        foreach ($source in $fixed.propertySources) {
            foreach ($property in $source.source.PSObject.Properties) {
                if (!$values.ContainsKey($property.Name)) { $values[$property.Name] = $property.Value }
            }
        }
        $configurations[$service] = $values
        $report.Configurations += [pscustomobject]@{ Service=$service; DefaultVersion=$default.version; ExplicitVersion=$fixed.version; Port=$values['server.port']; RemoteDdlAuto=$values['spring.jpa.hibernate.ddl-auto'] }
        Write-Host "$service : Config Server default/label fijo verificados"
    }
    $before = @(Get-ReadOnlySnapshot $configurations)
    $before | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $diagnostics 'bases-antes.json') -Encoding UTF8

    foreach ($service in $Lab15Business) {
        Assert-Lab15PortFree $Lab15Ports[$service]
        $main = switch ($service) {
            'categoria-service' { 'com.tecsup.CategoriaServiceApplication' }
            'producto-service' { 'com.tecsup.ProductoServiceApplication' }
            'cliente-service' { 'com.tecsup.ClienteServiceApplication' }
            'pedido-service' { 'com.tecsup.PedidoServiceApplication' }
        }
        $argument = New-ProbeArguments $service $main
        $stdout = Join-Path $diagnostics "$service-$runId.stdout.log"
        $stderr = Join-Path $diagnostics "$service-$runId.stderr.log"
        $client = Start-Process $java -ArgumentList $argument -WorkingDirectory (Join-Path $Lab15Root $service) -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        # Retener el handle antes de esperar: PowerShell 5.1 puede perder el
        # ExitCode de un Start-Process ya finalizado si no se abrio el handle.
        $null = $client.Handle
        if (!$client.WaitForExit(120000)) { throw "Tiempo agotado al validar $service." }
        $client.WaitForExit()
        if ($client.ExitCode -ne 0) { throw "El contexto $service fallo; revisar logs locales sanitizando cualquier salida." }
        $line = Get-Content $stdout | Where-Object { $_.StartsWith('LAB15_RESULT ') } | Select-Object -Last 1
        if (!$line) { throw "No se obtuvo comprobacion efectiva de $service." }
        $result = $line.Substring('LAB15_RESULT '.Length) | ConvertFrom-Json
        if (!$result.valid -or [int]$result.port -ne $Lab15Ports[$service]) { throw 'La sonda no confirma configuracion segura.' }
        $result | Add-Member -NotePropertyName Log -NotePropertyValue ".runtime/diagnostico/$service-$runId.stdout.log"
        $report.Clients += $result
        $client = $null
        Write-Host "$service : contexto real validado; Hibernate=validate; SQL solo lectura; proceso cerrado"
    }
    $after = @(Get-ReadOnlySnapshot $configurations)
    $after | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $diagnostics 'bases-despues.json') -Encoding UTF8
    $report.DatabaseUnchanged = ($before | ConvertTo-Json -Depth 10 -Compress) -eq ($after | ConvertTo-Json -Depth 10 -Compress)
    if (!$report.DatabaseUnchanged) { throw 'Las huellas SQL difieren. Investigar sin intentar revertir datos.' }
    $report.Completed = $true
} finally {
    # Solo procesos creados por esta invocacion; nunca procesos encontrados por puerto.
    if ($client -and !$client.HasExited) { Stop-Process -Id $client.Id -ErrorAction SilentlyContinue }
    if ($server -and !$server.HasExited) {
        $server.StandardInput.WriteLine('')
        $server.StandardInput.Flush()
        if (!$server.WaitForExit(30000)) { Stop-Process -Id $server.Id -ErrorAction SilentlyContinue }
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $diagnostics 'verificacion-base.json') -Encoding UTF8
}
$report
