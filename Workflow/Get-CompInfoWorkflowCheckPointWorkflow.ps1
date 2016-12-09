workflow Get-CompInfo
{
    # Get-NetAdapter
    Get-Process
    Get-Service
    Checkpoint-Workflow
}

Get-CompInfo -PSComputerName 12R207,12R208,08R201

