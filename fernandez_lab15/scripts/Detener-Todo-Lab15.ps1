[CmdletBinding(SupportsShouldProcess=$true)]
param()
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($entry in @(@('Grafana','Detener-Grafana.ps1','.runtime\grafana\proceso.json'),@('Prometheus','Detener-Prometheus.ps1','.runtime\prometheus\proceso.json'),@('Siete Java Lab 15','Detener-Lab15.ps1','.runtime\paso03\procesos.json'))) {
    if(!(Test-Path (Join-Path $root $entry[2]))) { Write-Host "$($entry[0]): no hay registro propio; se omite.";continue }
    if($PSCmdlet.ShouldProcess($entry[0],'Verificar identidad y detener exclusivamente procesos registrados')) {
        if($entry[1] -eq 'Detener-Lab15.ps1') { & (Join-Path $PSScriptRoot $entry[1]) -Paso 03 -Confirm:$false }
        else { & (Join-Path $PSScriptRoot $entry[1]) -Confirm:$false }
    }
}
Write-Host 'MariaDB de XAMPP y procesos ajenos se conservan. SQLite/TSDB no se eliminan.'
