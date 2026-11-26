param(
    [ValidateSet('todos','config-server','eureka-server','gateway-service','categoria-service','producto-service','cliente-service','pedido-service')]
    [string]$Servicio = 'todos',
    [ValidateSet('02','03')][string]$Paso = '03'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
$runtime = if ($Paso -eq '03') { Join-Path $Lab15Root '.runtime\paso03' } else { Join-Path $Lab15Root '.runtime' }
$null = New-Item -ItemType Directory $runtime -Force
$maven = (Get-Command mvn.cmd -ErrorAction Stop).Source
$services = if ($Servicio -eq 'todos') { @($Lab15Ports.Keys) } else { @($Servicio) }
# En Windows no se deben sobrescribir JAR de nuestros procesos activos.
# Prevenir el bloqueo antes de que jar:jar pueda escribir un artefacto parcial.
$javaProcesses = @(Get-CimInstance Win32_Process -Filter "name='java.exe' OR name='javaw.exe'")
foreach ($service in $services) {
    $active = @($javaProcesses | Where-Object {
        $_.CommandLine -like "*@../.runtime/paso02/$service.args*" -or
        $_.CommandLine -like "*@../.runtime/paso03/$service.args*" -or
        $_.CommandLine -like "*$(Join-Path $Lab15Root "$service\target\$service-0.0.1-SNAPSHOT.jar")*"
    })
    if ($active.Count) { throw "El JAR de $service esta en uso. Detenga solo los procesos propios con Detener-Lab15.ps1 y el -Paso correspondiente antes de compilar." }
}
$results = foreach ($service in $services) {
    $log = Join-Path $runtime "build-$service.log"
    Push-Location (Join-Path $Lab15Root $service)
    try {
        # Omite compilacion y ejecucion de pruebas; no carga contextos Spring.
        # PowerShell 5.1 convierte stderr nativo (incluidas advertencias de
        # Java 26) en ErrorRecord. El resultado real lo determina el exit code.
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & $maven '-B' '-ntp' '-Dmaven.test.skip=true' '-DskipTests' 'package' *> $log
            $code = $LASTEXITCODE
        } finally { $ErrorActionPreference = $previousPreference }
        $jar = Join-Path (Get-Location).Path "target\$service-0.0.1-SNAPSHOT.jar"
        $row = [pscustomobject]@{ Service=$service; ExitCode=$code; Success=($code -eq 0 -and (Test-Path $jar)); TestsExecuted=$false; JavaHome=$Lab15JavaHome; Log=$log.Substring($Lab15Root.Length+1).Replace('\','/'); JarSHA256=$(if (Test-Path $jar) { (Get-FileHash $jar -Algorithm SHA256).Hash }) }
        Write-Host "$service : exit=$code; pruebas omitidas"
        $row
    } finally { Pop-Location }
}
$results | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $runtime "compilacion-$Servicio.json") -Encoding UTF8
if (@($results | Where-Object { !$_.Success }).Count) {
    throw 'Al menos una compilacion fallo. Revisar los logs locales antes de cambiar dependencias.'
}
$results
