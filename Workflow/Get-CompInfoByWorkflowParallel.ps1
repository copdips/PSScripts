Workflow Get-CompInfoByWorkflowParallel {
    param(
        [String[]]$Computers
    )
    
    Foreach -Parallel ($cn in $Computers) {
        gcim -pscomputername $cn -ClassName win32_computersystem 
        gwmi -pscomputername $cn -ClassName win32_computersystem
        # Test-Connection $cn 
    }
}

$myComputers = '12R207','12R208'

# if Get-CimInstance, pscomputername = $cn
# if Get-WmiObject, pscomputername = localhost
Get-CompInfoByWorkflowParallel -Computers $myComputers -PSPersist $true | select pscomputername,caption,domain |ft -AutoSize
Get-CompInfoByWorkflowParallel -Computers $myComputers | select pscomputername,caption,domain |ft -AutoSize

