param([switch]$ReutilizarArboles)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
$runtime = Join-Path $Lab15Root '.runtime\paso03'
$maven = (Get-Command mvn.cmd -ErrorAction Stop).Source
$results = @()
foreach ($service in $Lab15Ports.Keys) {
    $output = Join-Path $runtime "dependencias-$service.txt"
    $log = Join-Path $runtime "maven-dependencias-$service.log"
    Push-Location (Join-Path $Lab15Root $service)
    try {
        if ($ReutilizarArboles) {
            if (!(Test-Path $output) -or !(Select-String -Path $log -SimpleMatch 'BUILD SUCCESS' -Quiet)) { throw 'No existe arbol Maven previamente resuelto con exito.' }
            $code=0
        } else {
            $previous = $ErrorActionPreference
            try {
                $ErrorActionPreference='Continue'
                & $maven '-B' '-ntp' '-Dmaven.test.skip=true' '-DskipTests' 'dependency:tree' '-Dincludes=io.micrometer:*,io.prometheus:*' '-DoutputType=text' "-DoutputFile=$output" *> $log
                $code=$LASTEXITCODE
            } finally { $ErrorActionPreference=$previous }
        }
        if ($code -ne 0) { throw "Fallo Maven dependency:tree para $service." }
        $lines = @(Get-Content $output | Where-Object { $_ -match '(io\.micrometer|io\.prometheus):' })
        if (!($lines -match 'io\.micrometer:micrometer-registry-prometheus:jar:')) { throw 'Maven no resolvio el registro Prometheus.' }
        [xml]$pom = Get-Content 'pom.xml' -Raw
        $direct = @($pom.project.dependencies.dependency | Where-Object artifactId -eq 'micrometer-registry-prometheus')
        $actuator = @($pom.project.dependencies.dependency | Where-Object artifactId -eq 'spring-boot-starter-actuator')
        if ($direct.Count -ne 1 -or $direct[0].version -or $actuator.Count -ne 1) { throw 'Dependencia duplicada, con version manual o falta Actuator.' }
        $results += [pscustomobject]@{Service=$service;ExitCode=$code;SpringBoot=$pom.project.parent.version;SpringCloud=$pom.project.properties.'spring-cloud.version';JavaLevel=$pom.project.properties.'java.version';DirectRegistryDeclarations=$direct.Count;ManualRegistryVersion=$false;DirectActuatorDeclarations=$actuator.Count;Dependencies=$lines;Evidence="dependencias-$service.txt"}
        Write-Host "$service : arbol Maven resuelto correctamente"
    } finally { Pop-Location }
}
# Los metadatos proceden de los JAR Boot realmente resueltos, no de una guia de otra version.
$bootCache = Join-Path $env:USERPROFILE '.m2\repository\org\springframework\boot'
$bootJar=Join-Path $bootCache 'spring-boot-micrometer-metrics\4.1.2\spring-boot-micrometer-metrics-4.1.2.jar'
$metadataDirectory=Join-Path $runtime 'metadata'
$null=New-Item -ItemType Directory $metadataDirectory -Force
Write-Host 'Validando metadatos con jar del JDK seleccionado y JSON.parse de Node existente.'
Push-Location $metadataDirectory
try {
    $previous=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        & (Join-Path $Lab15JavaHome 'bin\jar.exe') '-xf' $bootJar 'META-INF/spring-configuration-metadata.json' *> (Join-Path $runtime 'metadata-extract.log')
        $code=$LASTEXITCODE
    } finally { $ErrorActionPreference=$previous }
    if ($code -ne 0) { throw 'No se pudieron leer los metadatos del JAR efectivo.' }
} finally { Pop-Location }
$metadataFile=Join-Path $metadataDirectory 'META-INF\spring-configuration-metadata.json'
& 'C:\Program Files\nodejs\node.exe' (Join-Path $PSScriptRoot 'Resolver-Metadatos.mjs') $metadataFile (Join-Path $runtime 'propiedad-prometheus.json') (Split-Path $bootJar -Leaf)
if ($LASTEXITCODE -ne 0) { throw 'Los metadatos efectivos no admiten la propiedad solicitada.' }
$properties=@((Get-Content (Join-Path $runtime 'propiedad-prometheus.json') -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
if (!$properties.Count) { throw 'No se encontro la propiedad solicitada en los metadatos efectivos de Spring Boot 4.1.2.' }
$evidence = Join-Path $Lab15Root 'evidencias\02-micrometer'
foreach ($result in $results) { Copy-Item (Join-Path $runtime $result.Evidence) (Join-Path $evidence $result.Evidence) }
& 'C:\Program Files\nodejs\node.exe' (Join-Path $PSScriptRoot 'Consolidar-Dependencias.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Fallo al consolidar el arbol de dependencias real.' }
$properties | Format-List
