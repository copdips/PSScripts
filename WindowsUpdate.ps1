Using module PSWindowsUpdate : https://www.powershellgallery.com/packages/PSWindowsUpdate

# Check available windows updates
Get-ADComputer -Filter * | % {Get-WUList -ComputerName $_.name -Verbose}

# Install window updates
# import-module PSWindowsUpdate
# $PSWindowsUpdatePath = ("\\" + $env:computername + "\" + $((get-module PSWindowsUpdate).path)).replace(":","$")
# $scriptInString = "ipmo $PSWindowsUpdatePath ; Get-WUInstall -AcceptAll -AutoReboot | Out-File C:\PSWindowsUpdate.log"
# $ScriptInScriptBlock =[ScriptBlock]::Create($scriptInString) 

$ScriptInScriptBlock = {ipmo PSWindowsUpdate ; Get-WUInstall -AcceptAll -AutoReboot | Out-File C:\PSWindowsUpdate.log}
Get-ADComputer -Filter * | % { Invoke-WUInstall -ComputerName $_.name -Script $ScriptInScriptBlock -Confirm:$False}
Get-ADComputer -Filter * | % { Get-Content \\$($_.name)\c$\PSWindowsUpdate.log }
