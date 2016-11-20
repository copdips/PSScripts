# $credContoso = Get-Credential contoso\administrator

# $credContosoFile = 'D:\xiang\Dropbox\Certification\Microsoft\Powershell\credContoso.txt'

# read-host -assecurestring | convertfrom-securestring | out-file $credContosoFile

$userContoso = 'contoso\administrator'

# $passwordContoso = 'Password1' | convertto-securestring -AsPlainText -Force 

$passwordContoso = get-content $credContosoFile | convertto-securestring

$credContoso = new-object -typename System.Management.Automation.PSCredential -argumentlist $userContoso,$passwordContoso

$PSSessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

Enter-PSSession 12R201.contoso.com -Credential $credContoso -UseSSL -SessionOption $PSSessionOption

sl c:\temp
