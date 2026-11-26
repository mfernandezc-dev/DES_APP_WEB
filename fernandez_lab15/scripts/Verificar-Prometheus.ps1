param([ValidateRange(10,300)][int]$DuracionSegundos=120,[switch]$SinTrafico)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Entorno-Prometheus.ps1')
$arguments=@((Join-Path $PSScriptRoot 'Verificar-Servidor-Prometheus.mjs'),"--duracion=$DuracionSegundos")
if($SinTrafico) { $arguments += '--sin-trafico' }
& 'C:\Program Files\nodejs\node.exe' @arguments
if($LASTEXITCODE -ne 0) { throw 'La comprobacion real de Prometheus no termino satisfactoriamente; revisar evidencias propias.' }
