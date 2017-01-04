#Requires -Version 4.0
Configuration ScriptFolderVersion
{
    Param ($server = $env:computername)

    node $server
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
    }
}

ScriptFolderVersion -Server 12R208


Start-DscConfiguration .\ScriptFolderVersion

icm 12R208 {gp HKLM:\SOFTWARE\dsc}