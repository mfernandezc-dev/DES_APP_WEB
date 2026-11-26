param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('config-server','eureka-server','gateway-service','categoria-service','producto-service','cliente-service','pedido-service')]
    [string]$Servicio
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Entorno-Lab15.ps1')
Assert-NoLab14Process
Assert-Lab15PortFree $Lab15Ports[$Servicio]
$jar = Join-Path $Lab15Root "$Servicio\target\$Servicio-0.0.1-SNAPSHOT.jar"
if (!(Test-Path $jar)) { throw 'Primero compile el servicio con Compilar-Lab15.ps1.' }
$arguments = @(Get-Lab15Arguments $Servicio)
if ($Servicio -in $Lab15Business) {
    # Solo se inspecciona version/label; nunca se imprime la configuracion sensible.
    $config = Invoke-RestMethod "http://localhost:8888/$Servicio/dev/$Lab15Commit" -TimeoutSec 30
    if ($config.version -ne $Lab15Commit) { throw 'Config Server no devolvio el commit autorizado.' }
    $origin = @($config.propertySources | Where-Object name -like '*github.com/mfernandezc-dev/config-repo*')
    if (!$origin.Count) { throw 'La configuracion no procede del repositorio esperado.' }
}
Push-Location (Join-Path $Lab15Root $Servicio)
try {
    Write-Host "Lab 15: $Servicio; puerto $($Lab15Ports[$Servicio]); Java 26. Ctrl+C termina este proceso."
    & (Join-Path $Lab15JavaHome 'bin\java.exe') '-Dspring.devtools.restart.enabled=false' '-jar' $jar @arguments
    if ($LASTEXITCODE -ne 0) { throw "El servicio termino con codigo $LASTEXITCODE." }
} finally { Pop-Location }
