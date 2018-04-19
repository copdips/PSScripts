# https://support.microsoft.com/en-us/kb/934307
# It's better to use this comdlet when there's no other wusa process is also working on the computer
# There's no retrun code for the call of wusa.exe

function Install-HotFix {
    [cmdletbinding()]
    param
    (
        [String] $computername = $env:COMPUTERNAME,

        # Currently must be a target computer's local path due to PsRemoting Kerberos delegation, there're many ways to fix it.
        [String] $HotFixPath
    )

    #No more use WMICLASS to start the process on remote computer
    # $InstallString = "cmd.exe /c wusa.exe $HotFixPath /quiet /norestart"
    #([WMICLASS]"\\$computername\ROOT\CIMV2:win32_process").Create($UninstallString) | out-null
    Invoke-Command -cn $computername {cmd.exe /c wusa.exe $Using:HotFixPath /quiet /norestart}

    # Bug if there's other wusa is ongoing, and is taking much time
    while (@(Get-Process wusa -ComputerName $computername -ErrorAction SilentlyContinue).Count -ne 0) {
        Start-Sleep 3
        Write-Host "Waiting for $HotFixPath installation to finish ..."
    }
    Write-Host "$computername : Completed the installation of $HotFixPath"

}