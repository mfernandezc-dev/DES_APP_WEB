param([ValidateSet('antes','despues')][string]$Momento='despues')
# Reutiliza el inventario SHA-256 del PASO 04 sin escribir sus resultados.
$code=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Integridad-Paso04.ps1')).Replace('paso04','paso05').Replace('03-prometheus','04-grafana').Replace('PASO 04','PASO 05')
$code=$code.Replace('$PSScriptRoot',("'"+$PSScriptRoot.Replace("'","''")+"'"))
& ([scriptblock]::Create($code)) -Momento $Momento
