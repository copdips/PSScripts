# http://techibee.com/powershell/powershell-uninstall-windows-hotfixesupdates/1084

function Uninstall-HotFix {
    [cmdletbinding()]
    param(
        $computername = $env:COMPUTERNAME,
        [string] $HotFixID
    )            

    $hotFix = Get-WmiObject -ComputerName $computername -Class win32_quickfixengineering | Where-Object {$_.HotFixId -match $HotFixID}    


    if($hotFix) 
    {
        $hotFixNumber = $HotfixID.Replace("KB","")

        Write-Host "$computername : Found the hotfix $HotFixID ,and uninstalling it"
        # $UninstallString = "cmd.exe /c wusa.exe /uninstall /KB:$Using:hotFixNumber /quiet /norestart"
        # ([WMICLASS]"\\$computername\ROOT\CIMV2:win32_process").Create($UninstallString) | out-null
        Invoke-Command -cn $computername {cmd.exe /c wusa.exe /uninstall /KB:$Using:hotFixNumber /quiet /norestart}


        # Bug if there's other wusa ongoing
        while (@(Get-Process wusa -computername $computername -ErrorAction SilentlyContinue).Count -ne 0) {
            Start-Sleep 3
            Write-Host "Waiting for $HotFixID removal to finish ..."
        }
        write-host "$computername : Completed the uninstallation of $hotfixID"
    }
    
    else
    {         
        write-host "$computername : Given hotfix $hotfixID not found"
    }            

}
