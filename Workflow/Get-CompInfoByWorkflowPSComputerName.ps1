###########################
# Parrell Workflow methode
###########################

workflow Get-CompInfoByWorkflowPSComputerName {
    #Get-NetAdapter
    Get-Disk
    #Get-Volume
    Gwmi win32_bios | Select caption
}

 
measure-command {Get-CompInfoByWorkflowPSComputerName -PSComputerName 12R207, 12R208 -PSPersist $true}

Get-CompInfoByWorkflowPSComputerName -PSComputerName 12R207, 12R208 -PSPersist $true

Get-CompInfoByWorkflowPSComputerName -PSComputerName $myComputers -PSPersist $true

Get-CompInfoByWorkflowPSComputerName -PSComputerName $myComputers
measure-command {Get-CompInfoByWorkflowPSComputerName -PSComputerName $myComputers}


###########################
# Classic sequential method
###########################
function Get-FctCompInfo {
    param(
        [String[]]$Computers
    )

    $computers | % {
        icm -ComputerName $_ -ScriptBlock {
            #Get-NetAdapter
            Get-Disk
            #Get-Volume
            Gwmi win32_bios | Select caption
        }
    }
}

 Get-FctCompInfo -Computers $myComputers

 Measure-Command { Get-FctCompInfo -Computers $myComputers}