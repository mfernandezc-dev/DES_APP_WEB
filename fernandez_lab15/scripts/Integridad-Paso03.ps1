param([ValidateSet('antes','despues')][string]$Momento = 'antes')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ((Get-Location).Path -ne $root -or (Split-Path $root -Leaf) -ne 'fernandez_lab15') { throw 'Ejecutar exclusivamente desde fernandez_lab15.' }
$repo = Split-Path $root -Parent
$runtime = Join-Path $root '.runtime\paso03'
$null = New-Item -ItemType Directory $runtime -Force
function Get-Inventory([string]$Directory, [bool]$External) {
    $result = @{}
    $pending = New-Object 'Collections.Generic.Stack[string]'
    $pending.Push($Directory)
    while ($pending.Count) {
        foreach ($item in Get-ChildItem -LiteralPath $pending.Pop() -Force) {
            if ($item.PSIsContainer) {
                if ($item.Name -in @('.git','node_modules','.npm-cache') -or ($External -and $item.FullName -eq $root) -or
                    (!$External -and $item.Name -in @('.runtime','target'))) { continue }
                $pending.Push($item.FullName)
            } else {
                $relative = $item.FullName.Substring($Directory.Length + 1).Replace('\','/')
                $result[$relative] = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
            }
        }
    }
    return $result
}
$beforePath = Join-Path $runtime 'integridad-antes.json'
if ($Momento -eq 'antes' -and (Test-Path $beforePath)) { throw 'Ya existe linea base del PASO 03; no se sobrescribe.' }
$state = [ordered]@{Timestamp=(Get-Date).ToString('o');IndexSHA256=(Get-FileHash (Join-Path $repo '.git\index') -Algorithm SHA256).Hash;Head=(git rev-parse HEAD);Branch=(git branch --show-current);External=(Get-Inventory $repo $true);Local=(Get-Inventory $root $false);ExternalGitStatus=@(git status --porcelain=v1 --untracked-files=all | Where-Object { $_ -notmatch '^[ MARCUD?!]{2} fernandez_lab15/' })}
$state | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $runtime "integridad-$Momento.json") -Encoding UTF8
if ($Momento -eq 'antes') { Write-Host "Linea base: $($state.External.Count) archivos externos y $($state.Local.Count) archivos locales, evidencias incluidas."; return }
$before = Get-Content $beforePath -Raw | ConvertFrom-Json
$changed = @($before.External.PSObject.Properties | Where-Object { $state.External[$_.Name] -ne $_.Value } | ForEach-Object Name)
$added = @($state.External.Keys | Where-Object { !$before.External.PSObject.Properties[$_] })
$localChanged = @($before.Local.PSObject.Properties | Where-Object { $state.Local[$_.Name] -ne $_.Value } | ForEach-Object Name)
$localAdded = @($state.Local.Keys | Where-Object { !$before.Local.PSObject.Properties[$_] })
$evidenceChanges = @($localChanged + $localAdded | Where-Object { $_ -like 'evidencias/*' -and $_ -notlike 'evidencias/02-micrometer/*' })
$report = [ordered]@{ExternalFilesBefore=@($before.External.PSObject.Properties).Count;ExternalFilesAfter=$state.External.Count;ExternalChangedOrRemoved=$changed;ExternalAdded=$added;Lab14Files=@($before.External.PSObject.Properties | Where-Object Name -like 'fernandez_lab14/*').Count;Lab14Unchanged=(@($changed+$added | Where-Object { $_ -like 'fernandez_lab14/*' }).Count -eq 0);IndexSHA256Before=$before.IndexSHA256;IndexSHA256After=$state.IndexSHA256;IndexUnchanged=($before.IndexSHA256 -eq $state.IndexSHA256);ExternalGitStatusUnchanged=(($before.ExternalGitStatus -join "`n") -eq ($state.ExternalGitStatus -join "`n"));HeadUnchanged=($before.Head -eq $state.Head);Branch=$state.Branch;PriorEvidenceFiles=@($before.Local.PSObject.Properties | Where-Object { $_.Name -like 'evidencias/*' -and $_.Name -notlike 'evidencias/02-micrometer/*' }).Count;PriorEvidenceChanges=$evidenceChanges;PriorEvidenceUnchanged=($evidenceChanges.Count -eq 0);ModifiedLocalFiles=$localChanged;AddedLocalFiles=$localAdded;ExcludedOperationalDirectories=@('.git','node_modules','.npm-cache')}
$report | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $runtime 'integridad-resultado.json') -Encoding UTF8
[pscustomobject]$report | Select-Object ExternalFilesBefore,ExternalFilesAfter,Lab14Files,Lab14Unchanged,IndexUnchanged,ExternalGitStatusUnchanged,PriorEvidenceFiles,PriorEvidenceUnchanged | Format-List
