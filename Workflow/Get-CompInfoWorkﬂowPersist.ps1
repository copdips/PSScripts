workflow Get-CompInfo
{
    Get-process -PSPersist $true
    Get-Disk
    Get-service -PSPersist $true
}

Get-CompInfo
