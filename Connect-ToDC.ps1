# https://blog.kloud.com.au/2016/04/21/using-saved-credentials-securely-in-powershell-scripts/

# $credContoso = Get-Credential contoso\administrator

$credContosoFile = 'D:\xiang\Dropbox\Certification\Microsoft\Powershell\credContoso.txt'

# read-host -assecurestring | convertfrom-securestring | out-file $credContosoFile

$userContoso = 'contoso\administrator'

# $passwordContoso = 'Password1' | convertto-securestring -AsPlainText -Force

$passwordContoso = get-content $credContosoFile | convertto-securestring

$credContoso = new-object -typename System.Management.Automation.PSCredential -argumentlist $userContoso,$passwordContoso

$PSSessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

# Enter-PSSession 12R201.contoso.com -Credential $credContoso -UseSSL -SessionOption $PSSessionOption

Enter-PSSession 12R201 -Credential $credContoso

sl c:\DSC


# # Generate a random AES Encryption Key.
# $AESKey = New-Object Byte[] 32
# [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
	
# # Store the AESKey into a file. This file should be protected!  (e.g. ACL on the file to allow only select people to read)
# Set-Content $AESKeyFilePath $AESKey   # Any existing AES Key file will be overwritten		

# # Read the password
# $password = $passwordSecureString | ConvertFrom-SecureString -Key $AESKey
# Add-Content $credentialFilePath $password

# $username = "reasonable.admin@acme.com.au"
# $AESKey = Get-Content $AESKeyFilePath
# $pwdTxt = Get-Content $SecurePwdFilePath
# $securePwd = $pwdTxt | ConvertTo-SecureString -Key $AESKey
# $credObject = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePw