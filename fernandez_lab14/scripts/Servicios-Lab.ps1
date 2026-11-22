param(
    [ValidateSet('Capturar','Reiniciar','Detener')][string]$Accion = 'Capturar',
    [ValidateSet('categoria-service','producto-service','cliente-service','pedido-service')][string]$Servicio,
    [switch]$Simulacion
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$runtime = Join-Path $root '.runtime'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$inventory = Join-Path $runtime 'procesos-originales.json'
if ($Accion -eq 'Capturar') {
    if (Test-Path $inventory) { throw 'Inventario existente: no se sobrescribe.' }
    $rows = foreach ($p in Get-CimInstance Win32_Process -Filter "name = 'java.exe'") {
        if ($p.CommandLine -match '-classpath "([^"]+)" (com\.tecsup\.(?:Categoria|Producto|Cliente|Pedido)ServiceApplication)$') {
            $cp = $Matches[1]
            $main = $Matches[2]
            $classes = ($cp -split ';')[0]
            if (!$classes.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { continue }
            $dir = Split-Path (Split-Path $classes -Parent) -Parent
            [pscustomobject]@{Service=(Split-Path $dir -Leaf);PID=$p.ProcessId;Java=$p.ExecutablePath;Classpath=$cp;Main=$main;Directory=$dir}
        }
    }
    if (@($rows).Count -ne 4) { throw 'Se requieren los cuatro servicios identificados de este laboratorio.' }
    $rows | ConvertTo-Json -Depth 5 | Set-Content $inventory -Encoding UTF8
    $rows | Select-Object Service,PID,Directory
    exit
}
if (!$Servicio) { throw 'Especifique -Servicio.' }
$items = Get-Content $inventory -Raw | ConvertFrom-Json
$item = $items | Where-Object Service -eq $Servicio
if (!$item) { throw "Servicio no encontrado en inventario: $Servicio" }
$ports = @{'categoria-service'=8082;'producto-service'=8083;'cliente-service'=8084;'pedido-service'=8085}
$listeners = @(Get-NetTCPConnection -State Listen -LocalPort $ports[$Servicio] -ErrorAction SilentlyContinue)
$known = @(Get-CimInstance Win32_Process -Filter "name = 'java.exe'" | Where-Object {
    ($_.CommandLine.Contains($item.Directory) -and $_.CommandLine.EndsWith($item.Main)) -or
    $_.CommandLine.Contains((Join-Path $runtime "$Servicio.args"))
})
foreach ($processId in @(@($listeners.OwningProcess) + @($known.ProcessId) | Select-Object -Unique)) {
    if (!$processId) { continue }
    $p = Get-CimInstance Win32_Process -Filter "ProcessId = $processId"
    if (!$p -or !$p.CommandLine.Contains($root) -and !$p.CommandLine.Contains((Join-Path $runtime "$Servicio.args"))) {
        throw "Puerto ocupado por proceso ajeno/no identificado: $processId"
    }
    if (!$p.CommandLine.Contains($item.Main) -and !$p.CommandLine.Contains((Join-Path $runtime "$Servicio.args"))) {
        throw "Clase principal inesperada en PID $processId"
    }
    Stop-Process -Id $processId
    Wait-Process -Id $processId -Timeout 20 -ErrorAction SilentlyContinue
}
if ($Accion -eq 'Detener') { Write-Output "$Servicio detenido (solo proceso identificado)."; exit }
$argfile = Join-Path $runtime "$Servicio.args"
$profiles = if ($Simulacion) {'dev,lab'} else {'dev'}
# Rutas relativas para evitar la codificacion nativa de argfiles de Java en Windows.
$log = "../.runtime/$Servicio.log"
$cp = 'target/classes;' + (($item.Classpath -split ';' | Select-Object -Skip 1) -join ';').Replace('\','/')
$arguments = @('-Dspring.devtools.restart.enabled=false','-cp',('"'+$cp+'"'),$item.Main,
  "--spring.profiles.active=$profiles",'--spring.jpa.hibernate.ddl-auto=validate',
  "--logging.file.name=$log")
[IO.File]::WriteAllLines($argfile, $arguments, (New-Object Text.UTF8Encoding($false)))
$p = Start-Process -FilePath $item.Java -ArgumentList ('@"'+$argfile+'"') -WorkingDirectory $item.Directory -PassThru -RedirectStandardOutput (Join-Path $runtime "$Servicio.stdout.log") -RedirectStandardError (Join-Path $runtime "$Servicio.stderr.log")
Write-Output "$Servicio iniciado: PID=$($p.Id), perfiles=$profiles, ddl-auto=validate"
