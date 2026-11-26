# -JsonPrivado solo para el subproceso Node: no ejecutar ni redirigir a evidencias.
param([switch]$Preparar,[switch]$JsonPrivado)
. (Join-Path $PSScriptRoot 'Entorno-Grafana.ps1')
if($Preparar) {
    $null=New-Item -ItemType Directory $GrafPrivate -Force
    $sids=@([Security.Principal.WindowsIdentity]::GetCurrent().User,(New-Object Security.Principal.SecurityIdentifier('S-1-5-18')))
    function Test-PrivateAccess($security) {
        $rules=@($security.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
        $actual=@($rules | ForEach-Object { $_.IdentityReference.Value } | Sort-Object -Unique)
        $expected=@($sids | ForEach-Object Value | Sort-Object -Unique)
        return ($security.AreAccessRulesProtected -and $rules.Count -eq 2 -and ($actual -join ',') -eq ($expected -join ',') -and @($rules | Where-Object { $_.IsInherited -or $_.AccessControlType -ne 'Allow' -or $_.FileSystemRights -ne 'FullControl' -or [int]$_.InheritanceFlags -ne 3 -or $_.PropagationFlags -ne 'None' }).Count -eq 0)
    }
    # Reutilizar una DACL correcta evita tocar SACL y exigir SeSecurityPrivilege.
    if(!(Test-PrivateAccess (Get-Acl -LiteralPath $GrafPrivate))) {
        $acl=New-Object Security.AccessControl.DirectorySecurity
        $acl.SetAccessRuleProtection($true,$false)
        foreach($sid in $sids) {
            $rule=New-Object Security.AccessControl.FileSystemAccessRule($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
            $acl.AddAccessRule($rule)
        }
        [IO.Directory]::SetAccessControl($GrafPrivate,$acl)
    }
    if(!(Test-PrivateAccess (Get-Acl -LiteralPath $GrafPrivate))) { throw 'La DACL privada de Grafana no coincide con usuario actual y SYSTEM.' }
    if(!(Test-Path (Join-Path $GrafPrivate 'admin.clixml'))) {
        $bytes=New-Object byte[] 36
        $rng=[Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        $password=[Convert]::ToBase64String($bytes)
        $credential=New-Object Management.Automation.PSCredential('admin',(ConvertTo-SecureString $password -AsPlainText -Force))
        $credential | Export-Clixml -LiteralPath (Join-Path $GrafPrivate 'admin.clixml')
        [IO.File]::WriteAllText((Join-Path $GrafPrivate 'encryption.key'),[Guid]::NewGuid().ToString('N')+[Guid]::NewGuid().ToString('N'))
        $password=$null;$bytes=$null
    }
    Write-Host 'Credencial local cifrada con DPAPI y ACL privada preparada; no se muestra la clave.'
}
if($JsonPrivado) {
    $credential=Get-GrafanaCredential
    [pscustomobject]@{user=$credential.UserName;password=$credential.GetNetworkCredential().Password} | ConvertTo-Json -Compress
}
