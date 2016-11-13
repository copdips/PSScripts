
Write-Host "test 1" -ForegroundColor Green

$PowerShell = [Powershell]::Create()

[void]$PowerShell.AddScript({
    Start-Sleep –Seconds 10
    Get-Date
})

$PowerShell.Invoke()

Write-Host "test 2" -ForegroundColor Green

$Runspace = [runspacefactory]::CreateRunspace()

$PowerShell = [Powershell]::Create()

$PowerShell.runspace = $Runspace

$Runspace.Open()

[void]$PowerShell.AddScript({

    Get-Date

    Start-Sleep -Seconds 10

})

$AsyncObject = $PowerShell.BeginInvoke()