# Solo lectura. Reutiliza ResumenBases.java del PASO 01 y pasa secretos por stdin.
function Get-Lab15DatabaseSnapshot {
    param([ValidateSet('02','03')][string]$Paso = '02')
    $configurations = @{}
    foreach ($service in $Lab15Business) {
        $fixed = Invoke-RestMethod "http://localhost:8888/$service/dev/$Lab15Commit" -TimeoutSec 30
        if ($fixed.version -ne $Lab15Commit) { throw 'Commit de configuracion inesperado.' }
        $values = @{}
        foreach ($source in $fixed.propertySources) {
            foreach ($property in $source.source.PSObject.Properties) {
                if (!$values.ContainsKey($property.Name)) { $values[$property.Name] = $property.Value }
            }
        }
        $configurations[$service] = $values
    }
    $driver = Join-Path $env:USERPROFILE '.m2\repository\com\mysql\mysql-connector-j\9.7.0\mysql-connector-j-9.7.0.jar'
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = Join-Path $Lab15JavaHome 'bin\java.exe'
    $info.WorkingDirectory = $Lab15Root
    $info.Arguments = '-cp ".runtime/paso' + $Paso + ';' + $driver + '" ResumenBases'
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    $null = $process.Start()
    foreach ($service in $Lab15Business) {
        $values = $configurations[$service]
        foreach ($value in @($service, $values['spring.datasource.url'], $values['spring.datasource.username'], $values['spring.datasource.password'])) {
            $process.StandardInput.WriteLine([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$value)))
        }
    }
    $process.StandardInput.Close()
    $output = $process.StandardOutput.ReadToEnd()
    $errorOutput = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw 'La instantanea JDBC de solo lectura fallo; no se publican mensajes ni credenciales JDBC.' }
    return ($output | ConvertFrom-Json)
}
