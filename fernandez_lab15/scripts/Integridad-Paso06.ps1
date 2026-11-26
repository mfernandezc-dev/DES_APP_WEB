param([ValidateSet('antes','despues')][string]$Momento='despues')
$code=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Integridad-Paso04.ps1')).Replace('paso04','paso06').Replace('03-prometheus','05-pruebas-finales').Replace('PASO 04','PASO 06')
$code=$code.Replace('$PSScriptRoot',("'"+$PSScriptRoot.Replace("'","''")+"'"))
& ([scriptblock]::Create($code)) -Momento $Momento
