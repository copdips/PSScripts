#Requires -version 4.0

Configuration DemoUser
{
    $cred = (Get-Credential).Password

    node 12R201
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

$configData = @{
    AllNodes = @(
        @{
            NodeName = "12R201";
            PSDscAllowPlainTextPassword = $true
        }
    )
}

DemoUser -ConfigurationData $configData

Start-DscConfiguration C:\DemoUser -Verbose