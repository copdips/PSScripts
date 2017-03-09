# Requires -version 4.0
Configuration ScriptFolderVersionUnzip
{
    Param 
    (
        $modulePath = ($env:PSModulePath -split ';' | Where-Object {$_ -match 'Program Files'}),

        $Server = $env:computername
    )

    node $Server
    {
        File ScriptFiles
        {
            SourcePath = "\\contoso\netlogon\testDSC"
            DestinationPath = "C:\DSC"
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
        }

        Registry AddScriptVersion
        {
            Key = "HKEY_Local_Machine\Software\DSC"
            ValueName = "ScriptsVersion"
            ValueData = "2.0"
            Ensure = "Present"
        }

        Archive ZippedModule
        {
            DependsOn = "[File]ScriptFiles"
            Path = "C:\DSC\PoshModules\PoshModules.zip"
            Destination = $modulePath
            Ensure = "Present"
        }
    }
}

ScriptFolderVersionUnZip -output C:\server1Config -Server 12R207,12R208,08R201

Start-DscConfiguration -Path C:\server1Config -JobName Server1Config -force


