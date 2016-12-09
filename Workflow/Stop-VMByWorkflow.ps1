Workflow Stop-VMByWorkflow {

$runningVMs = Get-VM |? {$_.State -match 'run'}
    
    Foreach -Parallel ($vm in $runningVMs) {
      stop-vm $vm.name -Confirm:$false
    }
}

Stop-VMByWorkflow
