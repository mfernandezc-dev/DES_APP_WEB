$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if((Get-Location).Path -ne $root) { throw 'Ejecutar desde fernandez_lab15.' }
$runtime=Join-Path $root '.runtime\paso05'
$ops=Join-Path $root '.runtime\grafana'
$evidence=Join-Path $root 'evidencias\04-grafana'
foreach($p in @($runtime,$ops,$evidence)) { $null=New-Item -ItemType Directory $p -Force }
$receipt=Join-Path $ops 'instalacion.json'
if(Test-Path $receipt) { throw 'Existe recibo de Grafana; verificar y reutilizar, no reinstalar.' }
$arch=(Get-CimInstance Win32_ComputerSystem).SystemType
if($arch -notlike '*x64*') { throw 'Este paquete requiere Windows x64.' }
$version='13.3.2'
$metadataUrl="https://grafana.com/api/grafana/versions/$version"
$metadata=Invoke-RestMethod $metadataUrl -TimeoutSec 60
if(!$metadata.channels.stable -or $metadata.channels.preview -or $metadata.channels.beta -or $metadata.channels.nightly) { throw 'La version no es estable.' }
$package=@($metadata.packages | Where-Object { $_.arch -eq 'amd64' -and $_.os -eq 'win' -and $_.product -eq 'grafana' })
if($package.Count -ne 1 -or $package[0].url -notlike 'https://dl.grafana.com/*' -or $package[0].sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Paquete/checksum oficial no confirmado.' }
$package=$package[0]
$metadata | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $evidence 'release-oficial.json') -Encoding UTF8
$archive=Join-Path $runtime ([IO.Path]::GetFileName($package.url))
if(!(Test-Path $archive)) {
    & curl.exe --fail --location --retry 2 --silent --show-error --output $archive $package.url
    if($LASTEXITCODE -ne 0) { throw 'Descarga oficial no completada; conservar checkpoint.' }
}
$hash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if($hash -ne $package.sha256) { throw 'SHA-256 no coincide: no extraer ni ejecutar.' }
$destination='C:\Grafana';$fallback=$false
if(Test-Path $destination) { throw 'C:\Grafana ya existe; no se sobrescribe.' }
try { $null=New-Item -ItemType Directory $destination -ErrorAction Stop } catch [UnauthorizedAccessException] {
    $destination=Join-Path $root '.runtime\tools\grafana';$fallback=$true
    if(Test-Path $destination) { throw 'Destino alternativo existente; no se sobrescribe.' }
    $null=New-Item -ItemType Directory $destination
}
$entries=@(& tar.exe -tzf $archive)
if($LASTEXITCODE -ne 0 -or @($entries | Where-Object { $_ -match '(^/|^[A-Za-z]:|(^|/)\.\.(/|$))' }).Count) { throw 'Archivo tar no seguro.' }
& tar.exe -xzf $archive -C $destination --strip-components=1
if($LASTEXITCODE -ne 0) { throw 'Extraccion incompleta; no borrar ni sobrescribir automaticamente.' }
$exe=Join-Path $destination 'bin\grafana.exe'
if(!(Test-Path $exe)) { throw 'La distribucion no contiene bin/grafana.exe.' }
$versionOutput=(& $exe --version 2>&1 | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $versionOutput -notmatch [regex]::Escape($version)) { throw 'Version del binario no confirmada.' }
$help=(& $exe server --help 2>&1 | Out-String)
if($LASTEXITCODE -ne 0 -or $help -notmatch 'homepath' -or $help -notmatch 'config') { throw 'Comando server no confirmado.' }
[IO.File]::WriteAllText((Join-Path $evidence 'grafana-version.txt'),$versionOutput+"`n",(New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $runtime 'grafana-server-help.txt'),$help,(New-Object Text.UTF8Encoding($false)))
$result=[pscustomobject]@{Version=$version;Edition='OSS';Architecture='windows-amd64';DetectedSystemType=$arch;OfficialPage='https://grafana.com/grafana/download?edition=oss&platform=windows';ReleasePage="https://grafana.com/grafana/download/$version`?edition=oss&platform=windows";MetadataURL=$metadataUrl;DownloadURL=$package.url;ExpectedSHA256=$package.sha256;CalculatedSHA256=$hash;SHA256Verified=$true;ArchiveBytes=(Get-Item $archive).Length;InstallDirectory=$destination;Fallback=$fallback;Executable=$exe;ExecutableSHA256=(Get-FileHash $exe -Algorithm SHA256).Hash;VersionOutput=$versionOutput;Command='grafana.exe server --homepath ... --config ...';Timestamp=(Get-Date).ToString('o');PathModified=$false;WindowsServiceRegistered=$false}
$result | ConvertTo-Json -Depth 8 | Set-Content $receipt -Encoding UTF8
$result | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $evidence 'INSTALACION-GRAFANA.json') -Encoding UTF8
[pscustomobject]@{Phase='B';Completed=$true;Timestamp=(Get-Date).ToString('o');Version=$version;Receipt='.runtime/grafana/instalacion.json'} | ConvertTo-Json | Set-Content (Join-Path $runtime 'checkpoint-B.json') -Encoding UTF8
$result | Select-Object Version,InstallDirectory,SHA256Verified,Executable | Format-List
