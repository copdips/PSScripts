(New-Object -TypeName System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$xiangProxy = ''
$env:PIP_PROXY = $xiangProxy

# Restore Powershell $env:PSModulePath when enter into Powershell from Pwsh
if ($PSVersionTable.PSVersion.Major -lt 6) {
    $currentPSModulePath = $env:PSModulePath
    $newPSModulePath = $currentPSModulePath -replace '\\Powershell\\', '\WindowsPowershell\'
    [System.Collections.ArrayList]$newPSModulePathArrayList = $newPSModulePath -split ';'
    $newPSModulePathArrayList.Insert(2, 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules')
    $env:PSModulePath = ($newPSModulePathArrayList | Select-Object -Unique) -join ';'
} else {
    Import-Module C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\NetTCPIP\NetTCPIP.psd1 -Force
}

Set-PSReadlineOption -EditMode Emacs

#Python
$env:VIRTUAL_ENV_DISABLE_PROMPT = '1'

function Find-zxExecLocation {
    [CmdletBinding()]
    param(
        [string]$execName
    )

    $env:Path -split ';' | ForEach-Object {Get-ChildItem $_ $execName -ea 0}
}

function Enter-zxRDPSession {
    [CmdletBinding()]
    param(
        [String]$ComputerName,
        [Int]$Width = 800,
        [Int]$Hight = 800
    )

    $rdpCommand = "mstsc /v $ComputerName /w $Width /h $Hight"
    Invoke-Expression $rdpCommand
}

function Enter-zxPSSession {
    [CmdletBinding()]
    param (
        [String]$ComputerName
    )

    $psSession = New-PSSession $ComputerName

    if (-not $psProfileScriptBlock) {
        $psProfile = $profile | ForEach-Object CurrentUserAllHosts
        $psProfileScriptBlock = [scriptblock]::Create($(Get-Content $psProfile) -join [System.Environment]::NewLine)
    }

    Invoke-Command -Session $psSession -ScriptBlock {
        Set-Variable -Name zxPsComputerName -Value $Using:ComputerName -Option Constant
        Set-Variable -Name zxPsComputerNameLength -Value $zxPsComputerName.Length -Option Constant
    }
    Invoke-Command -Session $psSession -ScriptBlock $psProfileScriptBlock
    Enter-PSSession -Session $psSession
}

function Clone-zxGitRepo {
    [CmdletBinding()]
    param (
        [String]$gitUrl
    )

    try {
        $gitRepoName = (Split-Path $gitUrl -Leaf) -replace '.git$', ''
        git config --global http.proxy $xiangProxy
        git clone $gitUrl
        Push-Location
        Set-Location ./$gitRepoName
        git config --global --unset http.proxy
        git config http.proxy $xiangProxy
        Pop-Location
    }
    catch {
        Write-Host "Failed to clone $gitUrl" -ForegroundColor Red
    }
}

function Enter-zxCyberArkSshSession {
    [CmdletBinding()]
    param (
        [string]$ComputerName
    )

    $cyberArkLogin = ''
    $cyberArkLoginDomain = ''
    $cyberArkFinalAccount = ''
    $cyberArkFinalAccountAddress = ''
    $cyberArkPsmpServer = ''
    $sshCommand = "ssh $cyberArkLogin@$cyberArkLoginDomain%$cyberArkFinalAccount+$cyberArkFinalAccountAddress%$ComputerName@$cyberArkPsmpServer"

    Invoke-Expression $sshCommand
}

function Download-zxGitRepo {
    [CmdletBinding()]
    param (
        [String]$gitUrl
    )

    $gitZipUrl = ($gitUrl -replace '.git$', '') + '/archive/master.zip'
    $gitRepoName = (Split-Path $gitUrl -Leaf) -replace '.git$', ''
    $gitRepoZipName = $gitRepoName + '.zip'

    try {
        Invoke-WebRequest -Uri $gitZipUrl -OutFile $gitRepoZipName
    }
    catch {
        Write-Host "Failed to download $gitZipUrl" -ForegroundColor Red
    }

    Expand-Archive $gitRepoZipName
    Move-Item $gitLocalItem.FullName .
    Remove-Item $gitRepoName
    Rename-Item $gitLocalItem.Name $gitRepoName
    Remove-Item $gitRepoZipName
}
Function Get-zxGitBranch {
    try {
        $gitBranch = git branch 2>$null
        if ($gitBranch) {
            return ($gitBranch -split '\*' |  Select-Object -Last 1).Trim()
        }
        else {
            return ''
        }
    }
    catch {
        return ''
    }

}

Function Test-AdminMode {
    if ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).Groups -match 'S-1-5-32-544')) {
	return $True
    }
    else {
	return $False
    }
}

Function Test-DebugMode {
    if (Test-Path -Path Variable:/PSDebugContext) {
	return $True
    }
    else {
	return $False
    }
}

Function Get-zxPSVersion {
    $psVersionObject = $psVersionTable.PSVersion
    if ($psVersionObject.Major -lt 6) {
        $psVersion = "$($psVersionObject.Major).$($psVersionObject.Minor)"
    }
    elseIf ($psVersionObject.Major -ge 6) {
	$psVersion = "$($psVersionObject.Major).$($psVersionObject.Minor).$($psVersionObject.Patch)"
    }
    return $psVersion
}

Function Get-CurrentPath {
    $currentPath = (Get-Location | ForEach-Object Path) -Split '::' | Select-Object -Last 1
    return $currentPath
}

function Select-ColorString {
    [Cmdletbinding()]
    # [Alias('scs')]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Pattern = $(throw "$($MyInvocation.MyCommand.Name) : " `
                + "Cannot bind null or empty value to the parameter `"Pattern`""),

        [Parameter(
            ValueFromPipeline = $true,
            HelpMessage = "String or list of string to be checked against the pattern")]
        [String[]]$Content,

        [Parameter()]
        [ValidateSet(
            'Black',
            'DarkBlue',
            'DarkGreen',
            'DarkCyan',
            'DarkRed',
            'DarkMagenta',
            'DarkYellow',
            'Gray',
            'DarkGray',
            'Blue',
            'Green',
            'Cyan',
            'Red',
            'Magenta',
            'Yellow',
            'White')]
        [String]$ForegroundColor = 'Black',

        [Parameter()]
        [ValidateSet(
            'Black',
            'DarkBlue',
            'DarkGreen',
            'DarkCyan',
            'DarkRed',
            'DarkMagenta',
            'DarkYellow',
            'Gray',
            'DarkGray',
            'Blue',
            'Green',
            'Cyan',
            'Red',
            'Magenta',
            'Yellow',
            'White')]
        [ValidateScript( {
                if ($Host.ui.RawUI.BackgroundColor -eq $_) {
                    throw "Current host background color is also set to `"$_`", " `
                        + "please choose another color for a better readability"
                }
                else {
                    return $true
                }
            })]
        [String]$BackgroundColor = 'Yellow',

        [Switch]$CaseSensitive = $false,

        [Parameter(
            HelpMessage = "If true, write only not matching lines; " `
                + "if false, write only matching lines")]
        [Switch]$NotMatch = $false,

        [Parameter(
            HelpMessage = "If true, write all the lines; " `
                + "if false, write only matching lines")]
        [Switch]$KeepNotMatch = $false
    )

    begin {
    }

    process {
        foreach ($line in $Content) {
            $paramSelectString = @{
                Pattern       = $Pattern
                AllMatches    = $true
                CaseSensitive = $CaseSensitive
            }
            $matchList = $line | Select-String @paramSelectString

            if (0 -lt $matchList.Count) {
                if (-not $NotMatch) {
                    $startIndex = 0
                    foreach ($myMatch in $matchList.Matches) {
                        $length = $myMatch.Index - $startIndex
                        try {
                            Write-Host $line.Substring($startIndex, $length) -NoNewline
                        }
                        catch {
                        }
                        $paramWriteHost = @{
                            Object          = $line.Substring($myMatch.Index, $myMatch.Length)
                            NoNewline       = $true
                            ForegroundColor = $ForegroundColor
                            BackgroundColor = $BackgroundColor
                        }
                        Write-Host @paramWriteHost
                        $startIndex = $myMatch.Index + $myMatch.Length
                    }
                    Write-Host $line.Substring($startIndex)
                }
            }
            else {
                if ($KeepNotMatch -or $NotMatch) {
                    Write-Host "$line"
                }
            }
        }
    }

    end {
    }
}

$osVersion = Get-CimInstance Win32_OperatingSystem | ForEach-Object Caption
$lastRebootTime = (Get-CimInstance Win32_OperatingSystem | ForEach-Object LastBootUpTime).toString('yyyy-MM-dd HH:mm:ss')
Write-Host "$osVersion" -ForegroundColor Magenta
Write-Host "Last Reboot: $lastRebootTime" -ForegroundColor Magenta

Function Prompt() {
    $now = (Get-Date).toString("HH:mm:ss")
    $gitBranch = Get-zxGitBranch
    $psVersion = Get-zxPSVersion
    $path = Get-CurrentPath
    $pythonVenvPath = $env:VIRTUAL_ENV

    Write-Host
    Write-Host "$now" -ForegroundColor Cyan -NoNewline

    if (Test-DebugMode) {
	Write-Host ' ' -NoNewline
	Write-Host '[DBG]' -ForegroundColor Black -BackgroundColor Yellow -NoNewline
    }

    if (Test-AdminMode) {
	Write-Host ' [admin]' -ForegroundColor Red -NoNewline
    }
    else {
	Write-Host ' [user]' -ForegroundColor DarkGray -NoNewline
    }

    Write-Host " $($env:USERNAME) @ $($env:COMPUTERNAME) " -ForegroundColor Magenta -NoNewline
    Write-Host $path -ForegroundColor Green -NoNewline
    Write-Host " [" -ForegroundColor Yellow -NoNewline
    Write-Host "$gitBranch" -ForegroundColor Cyan -NoNewline
    Write-Host "]" -ForegroundColor Yellow

    if ($pythonVenvPath) {
        Write-Host "venv: $pythonVenvPath" -ForegroundColor DarkGray
    }

    if ($PSSenderInfo) {
        # in PS remote session
        $backspaces = "`b" * ($zxPsComputerNameLength + 4)
        $lastPrompt = "$psVersion remote>"
        $remaningChars = [Math]::Max( ($zxPsComputerNameLength + 4) - $lastPrompt.Length, 0 )
        $tail = (" " * $remaningChars) + ("`b" * $remaningChars)
        return "${backspaces}${lastPrompt}${tail}"
    } else {
        # in local session
        Write-Host "$psVersion>" -ForegroundColor Cyan -NoNewline
        return ' '
    }

}

Set-Alias gh Get-Help
Set-Alias wh Write-Host
Set-Alias wo Write-Output
Set-Alias so Select-Object
Set-Alias os Out-String
Set-Alias ep Enter-PSSession
Set-Alias fromjson ConvertFrom-Json
Set-Alias tojson ConvertTo-Json
Set-Alias tnc Test-NetConnection

Set-Alias go Enter-zxPSSession
Set-Alias rdp Enter-zxRDPSession
Set-Alias cssh Enter-zxCyberArkSshSession
Set-Alias which Find-zxExecLocation
Set-Alias cgit Clone-zxGitRepo
Set-Alias dgit Download-zxGitRepo
Set-Alias scs Select-ColorString

Set-Alias vi D:\xiang\Dropbox\tools\system\vim80-586rt\vim\vim80\vim.exe
Set-Alias vim D:\xiang\Dropbox\tools\system\vim80-586rt\vim\vim80\vim.exe
Set-Alias putty D:\xiang\Dropbox\tools\network\Putty\putty.exe
Set-Alias py python

$xiangGit = 'D:\xiang\git\'
