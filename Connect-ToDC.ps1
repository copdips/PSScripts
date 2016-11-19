$cred = Get-Credential contoso\administrator

$PSSessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

Enter-PSSession 12R201.contoso.com -Credential $cred -UseSSL -SessionOption $PSSessionOption

sl c:\temp

