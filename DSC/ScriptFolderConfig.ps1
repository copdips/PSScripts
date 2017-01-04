#Requires -version 4.0

Configuration ScriptFolder
{
    node '12R208'
    {
        File ScriptFiles
        {
            SourcePath = "\\contoso\netlogon\testDSC"
            DestinationPath = "C:\DSC"
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
        }
    }
}

ScriptFolder

Start-DscConfiguration .\ScriptFolder