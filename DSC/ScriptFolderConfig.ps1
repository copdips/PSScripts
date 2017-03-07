#Requires -version 4.0

Configuration ScriptFolder
{
    node '12R201'
    {
        File ScriptFiles
        {
            SourcePath = "\\contoso.com\netlogon\testDSC"
            #SourcePath = "\\12R201\C$\DSC\testDSC"
            DestinationPath = "C:\DSC"
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
        }
    }
}

ScriptFolder

Start-DscConfiguration .\ScriptFolder

get-job