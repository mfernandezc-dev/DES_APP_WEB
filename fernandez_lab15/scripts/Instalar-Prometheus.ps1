# Distribucion oficial portable; sin elevacion ni cambios permanentes de PATH.
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runtime=Join-Path $root '.runtime\prometheus'
$stepRuntime=Join-Path $root '.runtime\paso04'
$evidence=Join-Path $root 'evidencias\03-prometheus'
$null=New-Item -ItemType Directory $runtime,$stepRuntime,$evidence -Force
$architecture=(Get-CimInstance Win32_ComputerSystem).SystemType
if($architecture -notmatch 'x64') { throw 'Esta seleccion oficial es windows-amd64; no ejecutar en otra arquitectura.' }
$version='3.13.5'
$fileName="prometheus-$version.windows-amd64.zip"
$release="https://github.com/prometheus/prometheus/releases/download/v$version"
$expectedFromDownloadPage='846398b50b90e02f69960342190a1d01bf9a335b3aeee69bfd6ead41d3a314c5'
$destination='C:\Prometheus'
if(Test-Path $destination) { throw 'C:\Prometheus ya existe; no se sobrescribe una instalacion preexistente.' }
$archive=Join-Path $stepRuntime $fileName
$checksumFile=Join-Path $stepRuntime 'sha256sums-oficial.txt'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "$release/sha256sums.txt" -OutFile $checksumFile -UseBasicParsing -TimeoutSec 120
$pattern='^([a-fA-F0-9]{64})\s+\*?'+[regex]::Escape($fileName)+'\s*$'
$matchesFound=@(Get-Content $checksumFile | Where-Object { $_ -match $pattern })
if($matchesFound.Count -ne 1) { throw 'No existe un checksum oficial inequivoco para el paquete seleccionado.' }
$null=$matchesFound[0] -match $pattern
$expected=$Matches[1].ToLowerInvariant()
if($expected -ne $expectedFromDownloadPage) { throw 'Los checksums de la pagina oficial y del release no coinciden.' }
Write-Host "Descargando distribucion oficial LTS $version, windows-amd64..."
Invoke-WebRequest "$release/$fileName" -OutFile $archive -UseBasicParsing -TimeoutSec 600
$actual=(Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if($actual -ne $expected) { throw 'SHA-256 incorrecto: no se extrae ni ejecuta el paquete.' }
Write-Host "SHA-256 correcto: $actual"
$fallback=$false;$fallbackReason=$null
try { $null=New-Item -ItemType Directory $destination -ErrorAction Stop } catch {
    if(Test-Path $destination) { throw 'El destino aparecio durante la instalacion; no se sobrescribe.' }
    $fallback=$true;$fallbackReason=$_.Exception.GetType().Name
    $destination=Join-Path $root '.runtime\tools\prometheus'
    if(Test-Path $destination) { throw 'El destino portable alternativo ya existe; no se sobrescribe.' }
    $null=New-Item -ItemType Directory $destination -ErrorAction Stop
}
$staging=Join-Path $stepRuntime ('extraccion-'+[Guid]::NewGuid().ToString('N'))
Expand-Archive -LiteralPath $archive -DestinationPath $staging
$source=Join-Path $staging "prometheus-$version.windows-amd64"
if(!(Test-Path $source)) { throw 'La distribucion no contiene el directorio esperado.' }
Get-ChildItem $source -Force | Copy-Item -Destination $destination -Recurse
foreach($name in @('prometheus.exe','promtool.exe','prometheus.yml','LICENSE')) {
    if(!(Test-Path (Join-Path $destination $name))) { throw "Falta $name en la distribucion verificada." }
}
function Get-VersionEvidence([string]$Name) {
    $stdout=Join-Path $runtime "$Name-version.stdout.txt"
    $stderr=Join-Path $runtime "$Name-version.stderr.txt"
    $process=Start-Process (Join-Path $destination "$Name.exe") -ArgumentList '--version' -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null=$process.Handle;$process.WaitForExit();$process.WaitForExit()
    if($process.ExitCode -ne 0) { throw "Fallo $Name --version." }
    $text=([IO.File]::ReadAllText($stdout)+[IO.File]::ReadAllText($stderr)).Trim()
    if($text -notmatch [regex]::Escape($version) -or $text -notmatch 'windows/amd64') { throw 'Version o plataforma del ejecutable inesperada.' }
    [IO.File]::WriteAllText((Join-Path $evidence "$Name-version.txt"),$text+"`n",(New-Object Text.UTF8Encoding($false)))
    return $text
}
$prometheusVersion=Get-VersionEvidence 'prometheus'
$promtoolVersion=Get-VersionEvidence 'promtool'
$receipt=[ordered]@{Version=$version;Channel='LTS estable, segun pagina oficial consultada';Architecture='windows-amd64';DetectedSystemType=$architecture;OfficialPage='https://prometheus.io/download/';ReleasePage="https://github.com/prometheus/prometheus/releases/tag/v$version";DownloadUrl="$release/$fileName";ChecksumUrl="$release/sha256sums.txt";ExpectedSHA256=$expected;CalculatedSHA256=$actual;SHA256Verified=$true;ArchiveBytes=(Get-Item $archive).Length;InstallDirectory=$destination;PortableFallback=$fallback;FallbackReason=$fallbackReason;PreexistingInstallationOverwritten=$false;PrometheusExecutableSHA256=(Get-FileHash (Join-Path $destination 'prometheus.exe') -Algorithm SHA256).Hash;PromtoolExecutableSHA256=(Get-FileHash (Join-Path $destination 'promtool.exe') -Algorithm SHA256).Hash;Files=@(Get-ChildItem $destination | ForEach-Object Name);NoticeIncluded=(Test-Path (Join-Path $destination 'NOTICE'));PrometheusVersion=$prometheusVersion;PromtoolVersion=$promtoolVersion;Timestamp=(Get-Date).ToString('o');PathModified=$false;ElevationRequested=$false}
$receipt | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $runtime 'instalacion.json') -Encoding UTF8
$receipt | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $evidence 'INSTALACION-PROMETHEUS.json') -Encoding UTF8
Copy-Item $checksumFile (Join-Path $evidence 'sha256sums-oficial.txt')
Write-Host "Instalacion verificada en $destination; NOTICE incluido: $($receipt.NoticeIncluded)"
Write-Host $prometheusVersion
