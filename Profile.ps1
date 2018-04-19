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

Function Find-Word {
    # https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/
    [Cmdletbinding()]
    [Alias("Highlight")]
    Param(
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [String[]] $Words = $(throw "Provide word[s] to be highlighted!"),

        [Parameter(ValueFromPipeline = $true, Position = 0)] [string[]] $Content
    )

    Begin {
        $Color = @{
            0  = 'Yellow'
            1  = 'Magenta'
            2  = 'Red'
            3  = 'Cyan'
            4  = 'Green'
            5  = 'Blue'
            6  = 'DarkGray'
            7  = 'Gray'
            8  = 'DarkYellow'
            9  = 'DarkMagenta'
            10 = 'DarkRed'
            11 = 'DarkCyan'
            12 = 'DarkGreen'
            13 = 'DarkBlue'
        }

        $ColorLookup = @{}

        For ($i = 0; $i -lt $Words.count ; $i++) {
            if ($i -eq 13) {
                $j = 0
            }
            else {
                $j = $i
            }

            $ColorLookup.Add($Words[$i], $Color[$j])
            $j++
        }

    }

    Process {
        $Content | Select-String -List $Words | ForEach-Object {
            $lineString = $_.ToString()

            $TotalLength = 0

            $lineString.split() | `
                Where-Object {-not [string]::IsNullOrWhiteSpace($lineString)} | ` #Filter-out whiteSpaces
                ForEach-Object {
                if ($TotalLength -lt ($Host.ui.RawUI.BufferSize.Width - 10)) {
                    #"TotalLength : $TotalLength"
                    $Token = $_
                    $displayed = $False

                    Foreach ($Word in $Words) {
                        if ($Token -like "*$Word*") {
                            $Before, $after = $Token -Split "$Word"


                            #"[$Before][$Word][$After]{$Token}`n"

                            Write-Host $Before -NoNewline ;
                            Write-Host $Word -NoNewline -Fore Black -Back $ColorLookup[$Word];
                            Write-Host $after -NoNewline ;
                            $displayed = $true
                            #Start-Sleep -Seconds 1
                            #break
                        }

                    }
                    If (-not $displayed) {
                        Write-Host "$Token " -NoNewline
                    }
                    else {
                        Write-Host " " -NoNewline
                    }
                    $TotalLength = $TotalLength + $Token.Length + 1
                }
                else {
                    Write-Host '' #New Line
                    $TotalLength = 0

                }

                #Start-Sleep -Seconds 0.5

            }
            Write-Host '' #New Line
        }
    }

    end {
    }
}

Function Trace-Word {
    # https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/
    [Cmdletbinding()]
    [Alias("Highlight")]
    Param(
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [String[]] $Words = $(throw "Provide word[s] to be highlighted!"),

        [Parameter(ValueFromPipeline = $true, Position = 0)] [string[]] $Content
    )

    Begin {
        $Color = @{
            0  = 'Yellow'
            1  = 'Magenta'
            2  = 'Red'
            3  = 'Cyan'
            4  = 'Green'
            5  = 'Blue'
            6  = 'DarkGray'
            7  = 'Gray'
            8  = 'DarkYellow'
            9  = 'DarkMagenta'
            10 = 'DarkRed'
            11 = 'DarkCyan'
            12 = 'DarkGreen'
            13 = 'DarkBlue'
        }

        $ColorLookup = @{}

        For ($i = 0; $i -lt $Words.count ; $i++) {
            if ($i -eq 13) {
                $j = 0
            }
            else {
                $j = $i
            }

            $ColorLookup.Add($Words[$i], $Color[$j])
            $j++
        }

    }

    Process {
        $Content | ForEach-Object {

            $TotalLength = 0

            $_.split() | `
                Where-Object {-not [string]::IsNullOrWhiteSpace($_)} | ` #Filter-out whiteSpaces
                ForEach-Object {
                if ($TotalLength -lt ($Host.ui.RawUI.BufferSize.Width - 10)) {
                    #"TotalLength : $TotalLength"
                    $Token = $_
                    $displayed = $False

                    Foreach ($Word in $Words) {
                        if ($Token -like "*$Word*") {
                            $Before, $after = $Token -Split "$Word"


                            #"[$Before][$Word][$After]{$Token}`n"

                            Write-Host $Before -NoNewline ;
                            Write-Host $Word -NoNewline -Fore Black -Back $ColorLookup[$Word];
                            Write-Host $after -NoNewline ;
                            $displayed = $true
                            #Start-Sleep -Seconds 1
                            #break
                        }

                    }
                    If (-not $displayed) {
                        Write-Host "$Token " -NoNewline
                    }
                    else {
                        Write-Host " " -NoNewline
                    }
                    $TotalLength = $TotalLength + $Token.Length + 1
                }
                else {
                    Write-Host '' #New Line
                    $TotalLength = 0

                }

                #Start-Sleep -Seconds 0.5

            }
            Write-Host '' #New Line
        }
    }

    end {
    }

}

Function Find-Word {
    # https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/
    [Cmdletbinding()]
    [Alias("Highlight")]
    Param(
        [Parameter(Position = 0)]
        [ValidateNotNull()]
        [String[]] $Words = $(throw "Provide word[s] to be highlighted!"),

        [Parameter(ValueFromPipeline = $true, Position = 1)] [string[]] $Content
    )

    Begin {
        $Color = @{
            0  = 'Yellow'
            1  = 'Magenta'
            2  = 'Red'
            3  = 'Cyan'
            4  = 'Green'
            5  = 'Blue'
            6  = 'DarkGray'
            7  = 'Gray'
            8  = 'DarkYellow'
            9  = 'DarkMagenta'
            10 = 'DarkRed'
            11 = 'DarkCyan'
            12 = 'DarkGreen'
            13 = 'DarkBlue'
        }

        $ColorLookup = @{}

        For ($i = 0; $i -lt $Words.count ; $i++) {
            if ($i -eq 13) {
                $j = 0
            }
            else {
                $j = $i
            }

            $ColorLookup.Add($Words[$i], $Color[$j])
            $j++
        }

    }

    Process {
        $Content | Select-String -List $Words | ForEach-Object {
            $lineString = $_.ToString()

            $TotalLength = 0

            $lineString.split() | `
                Where-Object {-not [string]::IsNullOrWhiteSpace($lineString)} | ` #Filter-out whiteSpaces
                ForEach-Object {
                if ($TotalLength -lt ($Host.ui.RawUI.BufferSize.Width - 10)) {
                    #"TotalLength : $TotalLength"
                    $Token = $_
                    $displayed = $False

                    Foreach ($Word in $Words) {
                        if ($Token -like "*$Word*") {
                            $Before, $after = $Token -Split "$Word"


                            #"[$Before][$Word][$After]{$Token}`n"

                            Write-Host $Before -NoNewline ;
                            Write-Host $Word -NoNewline -Fore Black -Back $ColorLookup[$Word];
                            Write-Host $after -NoNewline ;
                            $displayed = $true
                            #Start-Sleep -Seconds 1
                            #break
                        }

                    }
                    If (-not $displayed) {
                        Write-Host "$Token " -NoNewline
                    }
                    else {
                        Write-Host " " -NoNewline
                    }
                    $TotalLength = $TotalLength + $Token.Length + 1
                }
                else {
                    Write-Host '' #New Line
                    $TotalLength = 0

                }

                #Start-Sleep -Seconds 0.5

            }
            Write-Host '' #New Line
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

Set-Alias go Enter-zxPSSession
Set-Alias rdp Enter-zxRDPSession
Set-Alias cssh Enter-zxCyberArkSshSession
Set-Alias which Find-zxExecLocation
Set-Alias cgit Clone-zxGitRepo
Set-Alias dgit Download-zxGitRepo
Set-Alias grep Find-Word
Set-Alias trace Trace-Word

Set-Alias vi D:\xiang\Dropbox\tools\system\vim80-586rt\vim\vim80\vim.exe
Set-Alias vim D:\xiang\Dropbox\tools\system\vim80-586rt\vim\vim80\vim.exe
Set-Alias putty D:\xiang\Dropbox\tools\network\Putty\putty.exe
Set-Alias py python

$xiangGit = 'D:\xiang\git\'
