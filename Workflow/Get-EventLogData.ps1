WorkFlow Get-EventLogData {
    $i =0
    Parallel {
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName application -Newest 1}
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName system -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
        Sequence {$WORKFLOW:i++ ; Sleep 5 ; Get-EventLog -LogName 'Windows PowerShell' -Newest 1 }
    }
}