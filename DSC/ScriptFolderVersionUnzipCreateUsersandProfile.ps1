#ScriptFolderVersionUnzipCreateUsersandProfile.ps1

#Requires -Version 4.0
Configuration ScriptFolder
{
    Param (
        $modulePath = ($env:PSModulePath -split ';' | ? {$_ -match 'Program Files'}),
        $Server = $env:computername
    )

    node $Server
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

        #Group Scripters
        #{
         #   GroupName = "Scripters"
          #  Credential = $cred
           # Description = "Scripting Dudes"
            #Members = @("ed")
            #DependsOn = "[user]Eduser"
        #}

        File ScriptFiles
        {
            SourcePath = "\\contoso.com\netlogon\testDSC"
            DestinationPath = "C:\scripts"
            Ensure = "present"
            Type = "Directory"
            Recurse = $true
        }

        Registry AddScriptVersion
        {
            Key = "HKEY_Local_Machine\Software\ForScripting"
            ValueName = "ScriptsVersion"
            ValueData = "1.0"
            Ensure = "Present"
        }

        Archive ZippedModule
        {
            DependsOn = "[File]ScriptFiles"
            Path = "C:\scripts\PoshModules\PoshModules.zip"
            Destination = $modulePath
            Ensure = "Present"
        }

        File PoshProfile
        {
            DependsOn = "[File]ScriptFiles"
            SourcePath = "C:\scripts\PoshProfiles\Microsoft.PowerShell_profile.ps1"
            DestinationPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
            Ensure = "Present"
            Type = "File"
            Recurse = $true
         }

    } # node 12R201

} # Configuration ScriptFolder

$cred = get-credential

$configData = @{
    AllNodes = @(
                    @{
            NodeName = "12R201";
            PSDscAllowPlainTextPassword = $true
        }
                @{
            NodeName = "12R207";
            PSDscAllowPlainTextPassword = $true
        }
                @{
            NodeName = "12R208";
            PSDscAllowPlainTextPassword = $true
        }
                @{
            NodeName = "08R201";
            PSDscAllowPlainTextPassword = $true
        }
    )
}

ScriptFolder -ConfigurationData $configData -Server 12R207,12R201,12R208,08R201

Start-DscConfiguration Scriptfolder