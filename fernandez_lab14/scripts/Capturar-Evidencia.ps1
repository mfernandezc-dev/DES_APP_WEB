param(
    [Parameter(Mandatory=$true)][string]$Url,
    [Parameter(Mandatory=$true)][string]$Archivo
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$uri=[Uri]$Url
if ($uri.Host -notin @('localhost','127.0.0.1') -or $uri.Scheme -ne 'http') {
    throw 'Solo se capturan paginas HTTP locales de este laboratorio.'
}
$evidence=[IO.Path]::GetFullPath((Join-Path $root 'evidencias'))
$image=[IO.Path]::GetFullPath((Join-Path $evidence $Archivo))
if (!$image.StartsWith($evidence+'\',[StringComparison]::OrdinalIgnoreCase) -or !($image.EndsWith('.png'))) {
    throw 'El PNG debe guardarse dentro de evidencias.'
}
if (Test-Path $image) { throw 'La captura ya existe: use otro nombre para no sobrescribir evidencia.' }
$browser='C:\Program Files\Google\Chrome\Application\chrome.exe'
if (!(Test-Path $browser)) { throw 'Chrome no encontrado. Capture manualmente la URL indicada.' }
New-Item -ItemType Directory -Path (Split-Path $image -Parent) -Force | Out-Null
$profile=Join-Path $root ('.runtime/chrome-'+[Guid]::NewGuid().ToString('N'))
$args='--headless=new --disable-gpu --no-first-run --no-default-browser-check --user-data-dir="'+$profile+'" --window-size=1400,1000 --screenshot="'+$image+'" "'+$uri.AbsoluteUri+'"'
$p=Start-Process $browser -ArgumentList $args -Wait -PassThru -RedirectStandardError ($profile+'.log')
if ($p.ExitCode -ne 0 -or !(Test-Path $image)) { throw 'No se genero una captura verificable.' }
@{Url=$uri.AbsoluteUri;Timestamp=(Get-Date -Format o);Browser='Chrome headless';Image=$Archivo;Bytes=(Get-Item $image).Length} |
    ConvertTo-Json | Set-Content ($image+'.json') -Encoding UTF8
Write-Output "Captura real guardada: $image (verificar visualmente antes de presentarla)."
