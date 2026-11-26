param([ValidateSet('antes','despues')][string]$Momento = 'antes')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repo = [IO.Path]::GetFullPath((Join-Path $root '..'))
$runtime = Join-Path $root '.runtime\paso02'
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
$index = Join-Path $repo '.git\index'
$state = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    IndexSHA256 = (Get-FileHash $index -Algorithm SHA256).Hash
    Head = (git rev-parse HEAD)
    Branch = (git branch --show-current)
    External = (Get-Inventory $repo $true)
    Local = (Get-Inventory $root $false)
    ExternalGitStatus = @(git status --porcelain=v1 --untracked-files=all | Where-Object { $_ -notmatch '^[ MARCUD?!]{2} fernandez_lab15/' })
}
$path = Join-Path $runtime "integridad-$Momento.json"
$state | ConvertTo-Json -Depth 6 | Set-Content $path -Encoding UTF8
if ($Momento -eq 'despues') {
    $before = Get-Content (Join-Path $runtime 'integridad-antes.json') -Raw | ConvertFrom-Json
    $changed = @($before.External.PSObject.Properties | Where-Object { $state.External[$_.Name] -ne $_.Value } | ForEach-Object Name)
    $added = @($state.External.Keys | Where-Object { !$before.External.PSObject.Properties[$_] })
    $lab14 = @($before.External.PSObject.Properties | Where-Object Name -like 'fernandez_lab14/*')
    $report = [ordered]@{
        ExcludedOperationalDirectories=@('.git','node_modules','.npm-cache')
        ExternalFilesBefore=@($before.External.PSObject.Properties).Count
        ExternalFilesAfter=$state.External.Count
        ExternalChangedOrRemoved=$changed
        ExternalAdded=$added
        Lab14Files=$lab14.Count
        Lab14Unchanged=(@($changed + $added | Where-Object { $_ -like 'fernandez_lab14/*' }).Count -eq 0)
        IndexSHA256Before=$before.IndexSHA256
        IndexSHA256After=$state.IndexSHA256
        IndexUnchanged=($before.IndexSHA256 -eq $state.IndexSHA256)
        ExternalGitStatusUnchanged=(($before.ExternalGitStatus -join "`n") -eq ($state.ExternalGitStatus -join "`n"))
        HeadUnchanged=($before.Head -eq $state.Head)
        Branch=$state.Branch
        ModifiedLocalFiles=@($before.Local.PSObject.Properties | Where-Object { $state.Local[$_.Name] -ne $_.Value } | ForEach-Object Name)
        AddedLocalFiles=@($state.Local.Keys | Where-Object { !$before.Local.PSObject.Properties[$_] })
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $runtime 'integridad-resultado.json') -Encoding UTF8
    $report | ConvertTo-Json -Depth 6
} else { Write-Host "Inventario previo conservado: $($state.External.Count) archivos externos; indice Git registrado." }
