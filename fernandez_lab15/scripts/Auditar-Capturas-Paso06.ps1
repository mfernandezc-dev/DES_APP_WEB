$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runtime=Join-Path $root '.runtime\paso06'
$evidence=Join-Path $root 'evidencias\05-pruebas-finales'
Add-Type -AssemblyName System.Drawing
$dirs=@('01-actuator','02-micrometer','03-prometheus','04-grafana')
$rows=@();$counts=@();$index=0;$sheet=$null;$graphics=$null;$pages=@()
foreach($d in $dirs) {
    $directory=Join-Path $root "evidencias\$d"
    $manifestFile=Get-ChildItem $directory -File -Filter 'CAPTURAS-PASO*.json' | Select-Object -First 1
    $manifest=Get-Content $manifestFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $files=@(Get-ChildItem $directory -File -Filter '*.png')
    $counts += [pscustomobject]@{Directory="evidencias/$d";Expected=@{ '01-actuator'=18;'02-micrometer'=10;'03-prometheus'=17;'04-grafana'=14 }[$d];Actual=$files.Count}
    foreach($file in $files) {
        if($index%6 -eq 0) { $sheet=New-Object Drawing.Bitmap(1500,1365);$graphics=[Drawing.Graphics]::FromImage($sheet);$graphics.Clear([Drawing.Color]::White) }
        $image=New-Object Drawing.Bitmap($file.FullName)
        try {
            $meta=$manifest.captures | Where-Object file -eq $file.Name
            $colors=New-Object 'Collections.Generic.HashSet[int]';$bright=0
            for($y=90;$y -lt $image.Height;$y+=9) { for($x=10;$x -lt $image.Width;$x+=9) { $pixel=$image.GetPixel($x,$y);$null=$colors.Add($pixel.ToArgb());if($pixel.R -gt 160 -and $pixel.G -gt 160 -and $pixel.B -gt 160){$bright++} } }
            $valid=$image.Width -ge 1000 -and $image.Height -ge 600 -and $colors.Count -gt 30 -and $bright -gt 0 -and $meta -and $meta.bytes -eq $file.Length
            $url=if($meta.displayedUrl){$meta.displayedUrl}else{$meta.url}
            $rows += [pscustomobject]@{File="evidencias/$d/$($file.Name)";SHA256=(Get-FileHash $file.FullName -Algorithm SHA256).Hash;Bytes=$file.Length;Width=$image.Width;Height=$image.Height;PNGDecoded=$true;SampledColors=$colors.Count;NonEmpty=($colors.Count -gt 30 -and $bright -gt 0);ManifestMatched=[bool]$meta;BytesMatch=($meta.bytes -eq $file.Length);URL=$url;Timestamp=$meta.timestamp;Redactions=@($meta.redactions);TechnicalValid=[bool]$valid;OriginalPreserved=$true;VisualReview='Vista de auditoria + metadatos originales; muestras de texto y datos personales revisadas por actividad'}
            $slot=$index%6;$x=($slot%2)*750;$y=[Math]::Floor($slot/2)*455
            $graphics.DrawImage($image,[int]$x,[int]($y+28),750,425)
            $font=New-Object Drawing.Font('Arial',11)
            try { $graphics.DrawString("$d/$($file.Name)",$font,[Drawing.Brushes]::Black,[single]($x+5),[single]($y+5)) } finally { $font.Dispose() }
        } finally { $image.Dispose() }
        $index++
        if($index%6 -eq 0 -or $index -eq 59) { $page=Join-Path $runtime ('revision-capturas-'+[Math]::Ceiling($index/6)+'.png');$sheet.Save($page,[Drawing.Imaging.ImageFormat]::Png);$graphics.Dispose();$sheet.Dispose();$pages+=$page.Substring($root.Length+1).Replace('\','/') }
    }
}
$report=[pscustomobject]@{Timestamp=(Get-Date).ToString('o');ReportedTotal=59;ActualTotal=$rows.Count;Counts=$counts;AllTechnicalChecksPassed=($rows.Count -eq 59 -and @($rows | Where-Object {!$_.TechnicalValid}).Count -eq 0);Captures=$rows;PrivateReviewSheets=$pages;Scope='PNG, resolucion, pixeles no vacios, procedencia y bytes del manifiesto; revision visual de las imagenes, sin afirmar que un analizador de pixeles demuestra por si solo autenticidad o ausencia de secretos'}
$report | ConvertTo-Json -Depth 14 | Set-Content (Join-Path $evidence 'AUDITORIA-CAPTURAS.json') -Encoding UTF8
if(!$report.AllTechnicalChecksPassed){throw 'Alguna captura anterior necesita revision; no se elimina ni sobrescribe.'}
[pscustomobject]@{Phase='C';Completed=$true;PreviousPNGs=$rows.Count;ContactSheets=$pages.Count;Evidence='AUDITORIA-CAPTURAS.json'} | ConvertTo-Json | Set-Content (Join-Path $runtime 'checkpoint-capturas.json') -Encoding UTF8
$counts | Format-Table
