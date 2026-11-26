# Cargar dentro del proceso PowerShell que va a compilar o ejecutar Lab 15.
# No escribe variables de usuario/maquina ni requiere privilegios.
$ErrorActionPreference = 'Stop'
$Lab15Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Lab15JavaHome = Join-Path $env:USERPROFILE '.jdks\corretto-26.0.2.1'
$Lab15Commit = '39a22fc2d854d3549ce77cbb347cd20101b0d13f'
$Lab15Ports = [ordered]@{
    'config-server' = 8888
    'eureka-server' = 8761
    'gateway-service' = 8080
    'categoria-service' = 8082
    'producto-service' = 8083
    'cliente-service' = 8084
    'pedido-service' = 8085
}
$Lab15Business = @('categoria-service','producto-service','cliente-service','pedido-service')
if (!(Test-Path (Join-Path $Lab15JavaHome 'bin\javac.exe'))) {
    throw 'No se encontro el JDK 26 esperado. No se instala ni cambia otro JDK automaticamente.'
}
$release = Get-Content (Join-Path $Lab15JavaHome 'release')
if (!($release -match '^JAVA_VERSION="26\.')) { throw 'La instalacion seleccionada no es Java 26.' }
$env:JAVA_HOME = $Lab15JavaHome
$env:PATH = (Join-Path $Lab15JavaHome 'bin') + ';' + $env:PATH

function Assert-Lab15PortFree([int]$Port) {
    $listeners = @(Get-NetTCPConnection -State Listen -ErrorAction Stop | Where-Object LocalPort -eq $Port)
    if ($listeners.Count) {
        throw "Puerto $Port ocupado (PID $($listeners[0].OwningProcess)). No se detiene ningun proceso automaticamente."
    }
}

function Assert-NoLab14Process {
    $oldRoot = [IO.Path]::GetFullPath((Join-Path $Lab15Root '..\fernandez_lab14'))
    $running = @(Get-CimInstance Win32_Process -Filter "name = 'java.exe' OR name = 'javaw.exe'" |
        Where-Object { $_.CommandLine -and $_.CommandLine.IndexOf($oldRoot, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    if ($running.Count) { throw 'Hay procesos Java de Lab 14. No se permite ejecutar ambos laboratorios simultaneamente.' }
}

function Get-Lab15Arguments([string]$Service) {
    $arguments = @(
        "--server.port=$($Lab15Ports[$Service])",
        '--server.address=127.0.0.1',
        '--management.endpoints.web.exposure.include=*',
        '--management.endpoint.health.show-details=always',
        '--management.prometheus.metrics.export.enabled=true',
        '--management.endpoint.env.show-values=never',
        '--management.endpoint.configprops.show-values=never'
    )
    if ($Service -ne 'config-server' -and $Service -ne 'eureka-server') {
        # Los listeners solo aceptan loopback; Eureka debe anunciar loopback.
        $arguments += @('--eureka.instance.hostname=localhost',
            '--eureka.instance.ip-address=127.0.0.1','--eureka.instance.prefer-ip-address=true')
    }
    if ($Service -eq 'gateway-service') {
        $arguments += '--spring.cloud.gateway.server.webflux.discovery.locator.enabled=false'
    }
    if ($Service -eq 'config-server') {
        # El clon de solo lectura queda FUERA del repositorio del curso.
        # Cache nuevo por proceso: clone-on-start no debe intentar borrar
        # packfiles Git de solo lectura dejados por una ejecucion anterior.
        $cache = Join-Path $env:LOCALAPPDATA ('Temp\opencode\lab15-config-cache-' + [Guid]::NewGuid().ToString('N'))
        $arguments += "--spring.cloud.config.server.git.basedir=$($cache.Replace('\','/'))"
        $arguments += "--spring.cloud.config.server.git.default-label=$Lab15Commit"
    }
    if ($Service -in $Lab15Business) {
        $arguments += @(
            '--spring.profiles.active=dev',
            '--spring.config.import=configserver:http://localhost:8888',
            "--spring.cloud.config.label=$Lab15Commit",
            '--spring.jpa.hibernate.ddl-auto=validate',
            '--spring.jpa.properties.hibernate.hbm2ddl.auto=validate',
            '--spring.jpa.generate-ddl=false',
            '--spring.sql.init.mode=never',
            '--spring.flyway.enabled=false',
            '--spring.liquibase.enabled=false',
            '--spring.datasource.hikari.read-only=true',
            '--spring.datasource.hikari.connection-init-sql=SET SESSION TRANSACTION READ ONLY'
        )
    }
    return $arguments
}
