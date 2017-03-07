#Requires -version 4.0

Configuration DemoUser
{
    $Password = Get-Credential

    node Server1
    {
        User EdUser
        {
            UserName = "ed"
            Password = $cred
            Description = "local ed account"
            Ensure = "Present"
            Disabled = $false
            PasswordNeverExpires = $true
            PasswordChangeRequired = $false
        }
    }
}

DemoUser