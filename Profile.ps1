# Profile location : $home\Documents\WindowsPowerShell\Profile.ps1
# All profiles locations : $profile | get-member -MemberType noteproperty

$env:path = "C:\Program Files (x86)\VMware\VMware vSphere CLI\bin;" + $env:path

Set-Alias gh Get-Help
Set-Alias im Import-Module
Set-Alias wh Write-Host
Set-Alias so Select-Object

set-alias vi D:\xiang\Dropbox\tools\system\vim74w32\vim\vim74\vim.exe
set-alias vim D:\xiang\Dropbox\tools\system\vim74w32\vim\vim74\vim.exe
set-alias putty D:\xiang\Dropbox\tools\network\Putty\putty.exe

function Set-Profile
{
    Ise $profile
}


#Start-Transcript

$systemLocaleName = (Get-WinSystemLocale).Name
if ($systemLocaleName -eq 'zh-CN'){
    chcp 65001
}

Function Prompt()
{
    $now = Get-Date
    $path = Get-Location | Select-Object -ExpandProperty ProviderPath
    $host.UI.RawUI.WindowTitle = $path
    $fullPSVersion = $PSVersionTable.PSVersion
    $shortPSVersion = $fullPSVersion.Major.toString() + '.' + $fullPSVersion.Minor.toString()

    Write-Host ""
    Write-Host "$($now.toString("HH:mm:ss")) " -ForegroundColor Cyan -NoNewline
    Write-Host "$($env:USERNAME) @ $($env:COMPUTERNAME) " -ForegroundColor Magenta -NoNewline
    Write-Host $path -ForegroundColor Green

    Write-Host "$shortPSVersion>" -BackgroundColor Darkcyan -ForegroundColor Black -NoNewLine

    return ' '

}
