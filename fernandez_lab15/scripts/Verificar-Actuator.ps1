# Evidencia HTTP real y solo GET. No descarga env completo, heapdump o configuraciones sensibles.
param([ValidateSet('02','03','04','05','06')][string]$Paso = '03', [switch]$OmitirTrafico)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
. (Join-Path $PSScriptRoot 'Huellas-Bases.ps1')
$runtime = Join-Path $Lab15Root ".runtime\paso$Paso"
$processPaso = if ($Paso -in @('04','05','06')) { '03' } else { $Paso }
$processRuntime = Join-Path $Lab15Root ".runtime\paso$processPaso"
$evidence = Join-Path $Lab15Root $(if ($Paso -eq '06') { 'evidencias\05-pruebas-finales' } elseif ($Paso -eq '05') { 'evidencias\04-grafana' } elseif ($Paso -eq '04') { 'evidencias\03-prometheus' } elseif ($Paso -eq '03') { 'evidencias\02-micrometer' } else { 'evidencias\01-actuator' })
$responses = Join-Path $evidence 'respuestas'
$null = New-Item -ItemType Directory $responses -Force
$script:requests = @()
function Protect-Evidence($Value, [bool]$Personal = $false) {
    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value.GetType().IsPrimitive -or $Value -is [decimal]) { return $Value }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [pscustomobject] -and $Value -isnot [System.Collections.IDictionary]) {
        $list = @(); foreach ($item in $Value) { $list += ,(Protect-Evidence $item $Personal) }; return ,$list
    }
    $safe = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) {
        if ($property.Name -match '(?i)password|secret|token|cookie|authorization|credential|email|correo|telefono|dni|direccion|apellido' -or
            ($Personal -and $property.Name -match '^(nombre|nombres)$')) {
            $safe[$property.Name] = '[REDACTADO]'
        } else { $safe[$property.Name] = Protect-Evidence $property.Value $Personal }
    }
    return [pscustomobject]$safe
}
function Read-Get([string]$Url, [string]$File, [string]$Group) {
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $status = 0; $text = ''; $data = $null
    try {
        $response = Invoke-WebRequest $Url -UseBasicParsing -TimeoutSec 40 -Headers @{Accept='application/json'}
        $status = [int]$response.StatusCode
        $text = if ($response.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($response.Content) } else { [string]$response.Content }
    } catch {
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
            $reader = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
            try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
        }
    }
    $timer.Stop()
    try { $data = $text | ConvertFrom-Json } catch { $data = $null }
    $row = [pscustomobject]@{Method='GET'; Url=$Url; Status=$status; DurationMs=$timer.ElapsedMilliseconds; Group=$Group; Timestamp=(Get-Date).ToString('o'); Evidence=$null}
    if ($File) {
        $relative = "respuestas/$File.json"
        $row.Evidence = $relative
        $safe = Protect-Evidence $data ($Url -match '/api/(clientes|pedidos)')
        [ordered]@{Method='GET';Url=$Url;Status=$status;Timestamp=$row.Timestamp;RedactedPersonalData=($Url -match '/api/(clientes|pedidos)');Body=$safe} |
            ConvertTo-Json -Depth 50 | Set-Content (Join-Path $responses "$File.json") -Encoding UTF8
    }
    $script:requests += $row
    return [pscustomobject]@{Status=$status; Data=$data; Text=$text; Record=$row}
}

$report = [ordered]@{Step=$Paso;Timestamp=(Get-Date).ToString('o');Target='Servicios reales localhost, sin mocks';Commit=$Lab15Commit;TestsExecuted=$false;HttpMethods=@('GET');Builds=@();Processes=@();Actuator=@();Health=@();Eureka=$null;Functional=@();Metrics=@();GatewayIsolation=@();Protections=@();Database=$null;Requests=@();Screenshots=$null;Completed=$false}
try {
    $buildPath = if ($Paso -in @('03','04','05','06')) { Join-Path $processRuntime 'compilacion-todos.json' } else { Join-Path $Lab15Root '.runtime\compilacion-todos.json' }
    $report.Builds = @((Get-Content $buildPath -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
    $registry = Get-Content (Join-Path $processRuntime 'procesos.json') -Raw | ConvertFrom-Json
    foreach ($record in $registry) {
        $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($record.PID)"
        $listeners = @(Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq $record.Port)
        $owned = $process -and $process.CommandLine -like "*@../.runtime/paso$processPaso/$($record.Service).args*"
        $localOnly = $listeners.Count -gt 0 -and @($listeners | Where-Object { $_.LocalAddress -notin @('127.0.0.1','::1') -or $_.OwningProcess -ne $record.PID }).Count -eq 0
        $report.Processes += [pscustomobject]@{Service=$record.Service;PID=$record.PID;Port=$record.Port;Running=[bool]$owned;LocalhostOnly=$localOnly;Stdout=$record.Stdout.Substring($Lab15Root.Length+1).Replace('\','/');Stderr=$record.Stderr.Substring($Lab15Root.Length+1).Replace('\','/')}
        $report.Protections += Get-Content (Join-Path $processRuntime "proteccion-$($record.Service).json") -Raw | ConvertFrom-Json
    }
    # Actividad principal primero; despues Categoria, Cliente, Pedido e infraestructura.
    $order = @('producto-service','categoria-service','cliente-service','pedido-service','config-server','eureka-server','gateway-service')
    $catalogues = @{}
    foreach ($service in $order) {
        $base = "http://localhost:$($Lab15Ports[$service])/actuator"
        foreach ($endpoint in @('','health','metrics')) {
            $suffix = if ($endpoint) { "/$endpoint" } else { '' }
            $name = if ($endpoint) { $endpoint } else { 'actuator' }
            $result = Read-Get "$base$suffix" "$service-$name" 'actuator-principal'
            $report.Actuator += $result.Record
            if ($endpoint -eq 'health') {
                $components = @($result.Data.components.PSObject.Properties | ForEach-Object { [pscustomobject]@{Name=$_.Name;Status=$_.Value.status} })
                $report.Health += [pscustomobject]@{Service=$service;Status=$result.Data.status;Http=$result.Status;Components=$components}
            }
            if ($endpoint -eq 'metrics') { $catalogues[$service] = @($result.Data.names) }
        }
    }
    $apps = Read-Get 'http://localhost:8761/eureka/apps' 'eureka-registros' 'eureka'
    $applications = @($apps.Data.applications.application)
    $registered = @($applications | ForEach-Object { $app=$_; foreach ($instance in @($app.instance)) { [pscustomobject]@{Name=$app.name;Status=$instance.status;Ip=$instance.ipAddr;Port=$instance.port.'$'} } })
    $expected = @('CATEGORIA-SERVICE','PRODUCTO-SERVICE','CLIENTE-SERVICE','PEDIDO-SERVICE','GATEWAY-SERVICE')
    $report.Eureka = [ordered]@{Http=$apps.Status;Registered=$registered;Expected=$expected;NotConfiguredToRegister=@('config-server','eureka-server');Missing=@($expected | Where-Object { $_ -notin $registered.Name })}

    $paths = [ordered]@{'categorias'=8082;'productos'=8083;'clientes'=8084;'pedidos'=8085}
    $businessData = @{}
    foreach ($path in $paths.Keys) {
        $gateway = Read-Get "http://localhost:8080/api/$path" "gateway-$path" 'funcional'
        $direct = Read-Get "http://localhost:$($paths[$path])/api/$path" "directo-$path" 'comparacion-directa'
        $businessData[$path] = $direct.Data
        $same = ($gateway.Data | ConvertTo-Json -Depth 40 -Compress) -eq ($direct.Data | ConvertTo-Json -Depth 40 -Compress)
        $fallback = $gateway.Text -match '(?i)temporal(mente)? no disponible|NO DISPONIBLE|"disponible"\s*:\s*false'
        $report.Functional += [pscustomobject]@{Url=$gateway.Record.Url;Status=$gateway.Status;Count=@($gateway.Data).Count;DirectStatus=$direct.Status;MatchesDirect=$same;UnexpectedFallback=[bool]$fallback;Evidence=$gateway.Record.Evidence}
    }
    $detail = Read-Get 'http://localhost:8085/api/pedidos?detallado=true' 'pedido-detallado' 'funcional-compuesta'
    $report.Functional += [pscustomobject]@{Url=$detail.Record.Url;Status=$detail.Status;Count=@($detail.Data).Count;UnexpectedFallback=[bool]($detail.Text -match '(?i)temporal(mente)? no disponible|NO DISPONIBLE|"disponible"\s*:\s*false');Evidence=$detail.Record.Evidence}
    $relations = @()
    foreach ($product in @($businessData['productos'])) {
        $category = @($businessData['categorias'] | Where-Object id -eq $product.categoriaId)[0]
        $relations += [pscustomobject]@{Check='Producto-Categoria';Id=$product.id;MatchesRealData=($null -ne $category -and $product.categoria.id -eq $category.id -and $product.categoria.nombre -eq $category.nombre -and $product.categoria.estado -eq $category.estado)}
    }
    foreach ($pedido in @($detail.Data)) {
        $client = @($businessData['clientes'] | Where-Object id -eq $pedido.cliente.id)[0]
        $product = @($businessData['productos'] | Where-Object id -eq $pedido.producto.id)[0]
        $relations += [pscustomobject]@{Check='Pedido-Cliente-Producto';Id=$pedido.id;MatchesRealData=($null -ne $client -and $null -ne $product -and $pedido.cliente.nombre -eq $client.nombre -and $pedido.cliente.apellido -eq $client.apellido -and $pedido.producto.nombre -eq $product.nombre -and $pedido.producto.precio -eq $product.precio)}
    }
    $report.RealDataRelations = $relations
    # Ejercita tambien el circuito de Cliente hacia Pedido usando el ID realmente devuelto.
    if (@($businessData['pedidos']).Count -gt 0) {
        $id = @($businessData['pedidos'])[0].idPedido
        if ($null -ne $id) {
            $compound = Read-Get "http://localhost:8084/api/clientes/pedidos/$id" 'cliente-pedido-real' 'funcional-compuesta'
            $report.Functional += [pscustomobject]@{Url=$compound.Record.Url;Status=$compound.Status;UnexpectedFallback=[bool]($compound.Text -match '(?i)temporal(mente)? no disponible|NO DISPONIBLE|"disponible"\s*:\s*false');Evidence=$compound.Record.Evidence}
        }
    }
    # Tres rondas secuenciales: no carga concurrente, ni perfiles con demoras artificiales.
    for ($round=1; !$OmitirTrafico -and $round -le 3; $round++) {
        foreach ($path in $paths.Keys) { $null = Read-Get "http://localhost:8080/api/$path" '' 'trafico-get-controlado' }
    }
    # Solo nombres presentes en el catalogo real; no se presupone disponibilidad.
    foreach ($service in $order) {
        $base = "http://localhost:$($Lab15Ports[$service])/actuator"
        $current = Read-Get "$base/metrics" "$service-metrics-final" 'catalogo-final'
        $names = @($current.Data.names)
        if ('http.server.requests' -in $names -and $service -in $Lab15Business) {
            $businessPath = switch ($service) { 'categoria-service' {'categorias'} 'producto-service' {'productos'} 'cliente-service' {'clientes'} 'pedido-service' {'pedidos'} }
            $filtered = Read-Get "$base/metrics/http.server.requests?tag=uri:/api/$businessPath&tag=method:GET&tag=status:200" "$service-http-get-negocio" 'http-negocio-filtrado'
            $report.Metrics += [pscustomobject]@{Service=$service;Name='http.server.requests (GET negocio, status 200)';Available=($filtered.Status -eq 200);Status=$filtered.Status;Measurements=$filtered.Data.measurements;Evidence=$filtered.Record.Evidence}
        }
        $wanted = @('jvm.memory.used','process.cpu.usage','system.cpu.usage','http.server.requests','hikaricp.connections.active','jdbc.connections.active','jdbc.connections.max','jdbc.connections.min')
        $wanted += @($names | Where-Object { $_ -like 'resilience4j.*' })
        foreach ($name in $wanted | Select-Object -Unique) {
            if ($name -in $names) {
                $result = Read-Get "$base/metrics/$name" "$service-metric-$name" 'metrica-especifica'
                $report.Metrics += [pscustomobject]@{Service=$service;Name=$name;Available=$true;Status=$result.Status;Measurements=$result.Data.measurements;Tags=$result.Data.availableTags;Evidence=$result.Record.Evidence}
            } else { $report.Metrics += [pscustomobject]@{Service=$service;Name=$name;Available=$false;Status=$null} }
        }
        if ($service -in @('producto-service','cliente-service','pedido-service')) {
            foreach ($endpoint in @('circuitbreakers','circuitbreakerevents','retries','retryevents','bulkheads','bulkheadevents')) {
                $null = Read-Get "$base/$endpoint" "$service-$endpoint" 'resilience4j'
            }
        }
    }
    foreach ($service in @('categoria-service','producto-service','cliente-service','pedido-service','gateway-service')) {
        $result = Read-Get "http://localhost:8080/$service/actuator/health" "gateway-bloqueo-$service" 'aislamiento-gateway'
        $report.GatewayIsolation += [pscustomobject]@{Url=$result.Record.Url;Status=$result.Status;Blocked=($result.Status -eq 404)}
    }
    $routes = Read-Get 'http://localhost:8080/actuator/gateway/routes' 'gateway-rutas' 'rutas'
    $report.GatewayRoutesHttp = $routes.Status
    $after = @(Get-Lab15DatabaseSnapshot -Paso $processPaso)
    $before = Get-Content (Join-Path $runtime 'bases-antes.json') -Raw | ConvertFrom-Json
    $after | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $runtime 'bases-despues.json') -Encoding UTF8
    $unchanged = ($before | ConvertTo-Json -Depth 10 -Compress) -eq ($after | ConvertTo-Json -Depth 10 -Compress)
    $report.Database = [ordered]@{Unchanged=$unchanged;Comparison='Conteos, SHA-256 de estructuras y todas las filas, antes/despues';Before=@($before | ForEach-Object { $_ });After=@($after | ForEach-Object { $_ })}
    $report.Completed = @($report.Actuator | Where-Object Status -ne 200).Count -eq 0 -and
        @($report.Health | Where-Object Status -ne 'UP').Count -eq 0 -and
        @($report.Functional | Where-Object { $_.Status -ne 200 -or $_.UnexpectedFallback -or $_.MatchesDirect -eq $false }).Count -eq 0 -and
        @($report.Processes | Where-Object { !$_.Running -or !$_.LocalhostOnly }).Count -eq 0 -and
        @($report.Protections | Where-Object { !$_.valid }).Count -eq 0 -and
        $report.Eureka.Missing.Count -eq 0 -and $unchanged -and @($report.GatewayIsolation | Where-Object { !$_.Blocked }).Count -eq 0 -and
        @($report.RealDataRelations | Where-Object { !$_.MatchesRealData }).Count -eq 0
} finally {
    $report.Requests = $script:requests
    $reportFile = if ($Paso -in @('03','04','05','06')) { 'REGRESION-ACTUATOR.json' } else { 'VERIFICACION-PASO02.json' }
    $report | ConvertTo-Json -Depth 50 | Set-Content (Join-Path $evidence $reportFile) -Encoding UTF8
}
[pscustomobject]@{Completed=$report.Completed;MainActuatorChecks=$report.Actuator.Count;Http200=@($report.Actuator | Where-Object Status -eq 200).Count;Requests=$script:requests.Count;DatabaseUnchanged=$report.Database.Unchanged;EurekaMissing=($report.Eureka.Missing -join ',')}
