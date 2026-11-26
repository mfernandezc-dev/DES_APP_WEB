param([Parameter(Mandatory=$true)][int]$BrowserPID, [Parameter(Mandatory=$true)][string]$OutputFile,
    [string]$OriginalFile, [string]$RedactionsFile)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Lab15Window {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int height, uint flags);
}
'@
$process = Get-Process -Id $BrowserPID
$process.Refresh()
$handle = $process.MainWindowHandle
if ($handle -eq [IntPtr]::Zero) { throw 'El navegador propio no tiene ventana capturable; usar las URL manuales.' }
$null = [Lab15Window]::ShowWindow($handle, 9)
$null = [Lab15Window]::SetWindowPos($handle, [IntPtr]::Zero, 0, 0, 1500, 850, 0x0040)
$null = [Lab15Window]::SetForegroundWindow($handle)
Start-Sleep -Milliseconds 1000
$rect = New-Object Lab15Window+RECT
if (![Lab15Window]::GetWindowRect($handle, [ref]$rect)) { throw 'No se pudo obtener el area de la ventana propia.' }
$bitmap = New-Object Drawing.Bitmap(($rect.Right-$rect.Left), ($rect.Bottom-$rect.Top))
$graphics = [Drawing.Graphics]::FromImage($bitmap)
try {
    # Capturar SOLO la ventana propia, aunque Windows no permita tomar foreground.
    $dc=$graphics.GetHdc()
    try {
        if (![Lab15Window]::PrintWindow($handle, $dc, 2)) { throw 'Windows no permitio capturar la ventana real.' }
    } finally { $graphics.ReleaseHdc($dc) }
    $bright = 0
    for ($y=90; $y -lt 500; $y+=3) {
        for ($x=15; $x -lt 1450; $x+=3) {
            $pixel=$bitmap.GetPixel($x,$y)
            if ($pixel.R -gt 150 -and $pixel.G -gt 150 -and $pixel.B -gt 150) { $bright++ }
        }
    }
    if ($bright -lt 30) { throw 'La pagina no esta renderizada; no se guarda una evidencia vacia.' }
    if ($OriginalFile) { $bitmap.Save($OriginalFile, [Drawing.Imaging.ImageFormat]::Png) }
    if ($RedactionsFile) {
        $regions = Get-Content $RedactionsFile -Raw | ConvertFrom-Json
        foreach ($region in $regions) {
            $rectangle = New-Object Drawing.RectangleF([single]$region.x,[single]$region.y,[single]$region.width,[single]$region.height)
            $graphics.FillRectangle([Drawing.Brushes]::Black,$rectangle)
            $font = New-Object Drawing.Font('Arial',8)
            try { $graphics.DrawString('[REDACTADO]',$font,[Drawing.Brushes]::White,$rectangle) } finally { $font.Dispose() }
        }
    }
    $bitmap.Save($OutputFile, [Drawing.Imaging.ImageFormat]::Png)
} finally {
    $graphics.Dispose(); $bitmap.Dispose()
}
