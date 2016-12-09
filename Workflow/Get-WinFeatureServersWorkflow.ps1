# Get-WinFeatureServersWorkflow.ps1
workflow get-winfeatures
{
    Parallel {
        InlineScript {import-module servermanager ; Get-WindowsFeature -Name PowerShell*}

        # $env:COMPUTERNAM inside InlineScript will be ran on the target computers
        # I can access an environmental variable from the remote servers. 
        # The InlineScript activity allows me to do things that otherwise would not be permitted in a Windows PowerShell workﬂow.
        InlineScript {$env:COMPUTERNAME}
        # $env:COMPUTERNAM without InlineScript will be ran only on the source computer
        $env:COMPUTERNAME

        Sequence {
            Get-date
            $PSVersionTable.PSVersion
        } 
    }
}

get-winfeatures -PSComputerName 12R207,12R208,08R201
