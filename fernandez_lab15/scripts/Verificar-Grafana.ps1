param([switch]$SoloConexion)
. (Join-Path $PSScriptRoot 'Entorno-Grafana.ps1')
$record=Get-Content (Join-Path $GrafRuntime 'proceso.json') -Raw | ConvertFrom-Json
if(!(Test-GrafanaIdentity $record)) { throw 'Grafana propio no coincide con el registro.' }
$arguments=@((Join-Path $PSScriptRoot 'Verificar-Grafana.mjs'))
if($SoloConexion) { $arguments += '--solo-conexion' }
& 'C:\Program Files\nodejs\node.exe' @arguments
if($LASTEXITCODE -ne 0) { throw 'Fallo en la verificacion real de Grafana; revisar checkpoint.' }
