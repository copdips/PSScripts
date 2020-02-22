Set-Variable -Name PSProfilePath -Value $PSCommandPath -Option Constant

$PSDefaultParameterValues['Select-String:AllMatches'] = $true
$PSDefaultParameterValues['Out-String:Stream'] = $true

# https://github.com/PowerShell/Win32-OpenSSH/wiki/TTY-PTY-support-in-Windows-OpenSSH
$env:TERM = 'xterm'

$fakeAdministratorPassword = "Password1" | ConvertTo-SecureString -asPlainText -Force
$fakeAdministratorName = "administrator"
$credFakeAdministrator = New-Object System.Management.Automation.PSCredential($fakeAdministratorName, $fakeAdministratorPassword)

(New-Object -TypeName System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$xzProxy = ''
$env:PIP_PROXY = $xzProxy

$typeIgnoreSslError = @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
            return true;
        }
	}
"@

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

# PsReadline has an startup issue with non ennglish keyboard.
# https://github.com/lzybkr/PSReadLine/issues/614
# Start-Job { {powershell Set-WinUserLanguageList -LanguageList en-us -Force} }

# Restore Powershell $env:PSModulePath when enter into Powershell from Pwsh
if ($PSVersionTable.PSVersion.Major -lt 6) {
    $currentPSModulePath = $env:PSModulePath
    $newPSModulePath = $currentPSModulePath -replace '\\Powershell\\', '\WindowsPowershell\'
    [System.Collections.ArrayList]$newPSModulePathArrayList = $newPSModulePath -split ';'
    $newPSModulePathArrayList.Insert(2, 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules')
    $env:PSModulePath = ($newPSModulePathArrayList | Select-Object -Unique) -join ';'
    Add-Type -TypeDefinition $typeIgnoreSslError
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
} else {
    $moduleWindowsCompatibility = Get-Module WindowsCompatibility -ListAvailable
    if (-not $moduleWindowsCompatibility) {
        Write-Host "Module WindowsCompatibility is not installed, please install it under admin with Install-Module WindowsCompatibility."
        Write-Host "Refer to :https://blogs.msdn.microsoft.com/powershell/2018/11/15/announcing-general-availability-of-the-windows-compatibility-module-1-0-0/"
    } else {
        Import-Module WindowsCompatibility
    }
}

Set-PSReadlineOption -EditMode Emacs

#Python
$env:VIRTUAL_ENV_DISABLE_PROMPT = '1'


function Enable-Proxy {
    # https://github.com/PowerShell/PowerShell/issues/3112
    $PSDefaultParameterValues["invoke-webrequest:proxy"] = $xzProxy
}


function Disable-Proxy {
    # https://github.com/PowerShell/PowerShell/issues/3112
    $PSDefaultParameterValues["invoke-webrequest:proxy"] = ""
}


function Select-zxColorString {
    <#
    .SYNOPSIS

    Find the matches in a given content by the pattern and write the matches in color like grep.

    .NOTES

    inspired by: https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString a

    Both line 'aa bb cc' and line 'A line' are displayed as both contain "a" case insensitive.

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString a -NotMatch

    Nothing will be displayed as both lines have "a".

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString a -CaseSensitive

    Only line 'aa bb cc' is displayed with color on all occurrences of "a" case sensitive.

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString '(a)|(\sb)' -CaseSensitive -BackgroundColor White

    Only line 'aa bb cc' is displayed with background color White on all occurrences of regex '(a)|(\sb)' case sensitive.

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString b -KeepNotMatch

    Both line 'aa bb cc' and 'A line' are displayed with color on all occurrences of "b" case insensitive,
    and for lines without the keyword "b", they will be only displayed but without color.

    .EXAMPLE

    > Get-Content app.log -Wait -Tail 100 | Select-ColorString "error|warning|critical" -MultiColorsForSimplePattern -KeepNotMatch

    Search the 3 key words "error", "warning", and "critical" in the last 100 lines of the active file app.log and display the 3 key words in 3 colors.
    For lines without the keys words, hey will be only displayed but without color.

    .EXAMPLE

    > Get-Content "C:\Windows\Logs\DISM\dism.log" -Tail 100 -Wait | Select-ColorString win

    Find and color the keyword "win" in the last ongoing 100 lines of dism.log.

    .EXAMPLE

    > Get-WinEvent -FilterHashtable @{logname='System'; StartTime = (Get-Date).AddDays(-1)} | Select-Object time*,level*,message | Select-ColorString win

    Find and color the keyword "win" in the System event log from the last 24 hours.
    #>

    [Cmdletbinding(DefaultParametersetName = 'Match')]
    param(
        [Parameter(
            Position = 0)]
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
                } else {
                    return $true
                }
            })]
        [String]$BackgroundColor = 'Yellow',

        [Parameter()]
        [Switch]$CaseSensitive,

        [Parameter(
            HelpMessage = "Available only if the pattern is simple non-regex string " `
                + "separated by '|', use this switch with fast CPU.")]
        [Switch]$MultiColorsForSimplePattern,

        [Parameter(
            ParameterSetName = 'NotMatch',
            HelpMessage = "If true, write only not matching lines; " `
                + "if false, write only matching lines")]
        [Switch]$NotMatch,

        [Parameter(
            ParameterSetName = 'Match',
            HelpMessage = "If true, write all the lines; " `
                + "if false, write only matching lines")]
        [Switch]$KeepNotMatch
    )

    begin {
        $paramSelectString = @{
            Pattern       = $Pattern
            AllMatches    = $true
            CaseSensitive = $CaseSensitive
        }
        $writeNotMatch = $KeepNotMatch -or $NotMatch

        [System.Collections.ArrayList]$colorList = [System.Enum]::GetValues([System.ConsoleColor])
        $currentBackgroundColor = $Host.ui.RawUI.BackgroundColor
        $colorList.Remove($currentBackgroundColor.ToString())
        $colorList.Remove($ForegroundColor)
        $colorList.Reverse()
        $colorCount = $colorList.Count

        if ($MultiColorsForSimplePattern) {
            # Get all the console foreground and background colors mapping display effet:
            # https://gist.github.com/timabell/cc9ca76964b59b2a54e91bda3665499e
            $patternToColorMapping = [Ordered]@{ }
            # Available only if the pattern is a simple non-regex string separated by '|', use this with fast CPU.
            # We dont support regex as -Pattern for this switch as it will need much more CPU.
            # This switch is useful when you need to search some words,
            # for example searching "error|warn|crtical" these 3 words in a log file.
            $expectedMatches = $Pattern.split("|")
            $expectedMatchesCount = $expectedMatches.Count
            if ($expectedMatchesCount -ge $colorCount) {
                Write-Host "The switch -MultiColorsForSimplePattern is True, " `
                    + "but there're more patterns than the available colors number " `
                    + "which is $colorCount, so rotation color list will be used." `
                    -ForegroundColor Yellow
            }
            0..($expectedMatchesCount - 1) | % {
                $patternToColorMapping.($expectedMatches[$_]) = $colorList[$_ % $colorCount]
            }

        }
    }

    process {
        foreach ($line in $Content) {
            $matchList = $line | Select-String @paramSelectString

            if (0 -lt $matchList.Count) {
                if (-not $NotMatch) {
                    $index = 0
                    foreach ($myMatch in $matchList.Matches) {
                        $length = $myMatch.Index - $index
                        Write-Host $line.Substring($index, $length) -NoNewline

                        $expectedBackgroupColor = $BackgroundColor
                        if ($MultiColorsForSimplePattern) {
                            $expectedBackgroupColor = $patternToColorMapping[$myMatch.Value]
                        }

                        $paramWriteHost = @{
                            Object          = $line.Substring($myMatch.Index, $myMatch.Length)
                            NoNewline       = $true
                            ForegroundColor = $ForegroundColor
                            BackgroundColor = $expectedBackgroupColor
                        }
                        Write-Host @paramWriteHost

                        $index = $myMatch.Index + $myMatch.Length
                    }
                    Write-Host $line.Substring($index)
                }
            } else {
                if ($writeNotMatch) {
                    Write-Host "$line"
                }
            }
        }
    }

    end {
    }
}


function Test-zxPort {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, HelpMessage = 'Could be suffixed by :Port')]
        [String[]]$ComputerName,

        [Parameter(HelpMessage = 'Will be ignored if the port is given in the param ComputerName')]
        [Int]$Port = 5985,

        [Parameter(HelpMessage = 'Timeout in millisecond. Increase the value if you want to test Internet resources.')]
        [Int]$Timeout = 1000
    )

    begin {
        $result = [System.Collections.ArrayList]::new()
    }

    process {
        foreach ($originalComputerName in $ComputerName) {
            $remoteInfo = $originalComputerName.Split(":")
            if ($remoteInfo.count -eq 1) {
                # In case $ComputerName in the form of 'host'
                $remoteHostname = $originalComputerName
                $remotePort = $Port
            } elseif ($remoteInfo.count -eq 2) {
                # In case $ComputerName in the form of 'host:port',
                # we often get host and port to check in this form.
                $remoteHostname = $remoteInfo[0]
                $remotePort = $remoteInfo[1]
            } else {
                $msg = "Got unknown format for the parameter ComputerName: " `
                    + "[$originalComputerName]. " `
                    + "The allowed formats is [hostname] or [hostname:port]."
                Write-Error $msg
                return
            }

            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $portOpened = $tcpClient.ConnectAsync($remoteHostname, $remotePort).Wait($Timeout)

            $null = $result.Add([PSCustomObject]@{
                RemoteHostname       = $remoteHostname
                RemotePort           = $remotePort
                TimeoutInMillisecond = $Timeout
                SourceHostname       = $env:COMPUTERNAME
                OriginalComputerName = $originalComputerName
                PortOpened           = $portOpened
                })
        }
    }

    end {
        return $result
    }
}


function Trace-zxWord {
    # https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/
    [Cmdletbinding()]
    [Alias("Highlight")]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNull()]
        [String[]] $Words = $(throw "Provide word[s] to be highlighted!"),

        [Parameter(ValueFromPipeline = $true, Position = 1)]
        [string[]] $Content
    )

    begin {
        # preparing a color lookup table

        $Color = [enum]::GetNames([System.ConsoleColor]) | Where-Object { $_ -notin @('White', 'Black') }
        [array]::Reverse($Color) # personal preference to color with lighter/dull shades at the end

        $Counter = 0
        $ColorLookup = [ordered]@{ }
        foreach ($item in $Words) {
            $ColorLookup.Add($item, $Color[$Counter])
            $Counter ++
            if ($Counter -gt ($Color.Count - 1)) {
                $Counter = 0
            }
        }

    }
    process {
        $Content | ForEach-Object {

            $TotalLength = 0

            $_.split() |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | #Filter-out whiteSpaces
            ForEach-Object {
                if ($TotalLength -lt ($Host.ui.RawUI.BufferSize.Width - 10)) {
                    #"TotalLength : $TotalLength"
                    $Token = $_
                    $displayed = $false

                    Foreach ($Word in $Words) {
                        if ($Token -like "*$Word*") {
                            $Before, $after = $Token -Split "$Word"

                            Write-Host $Before -NoNewline ;
                            Write-Host $Word -NoNewline -Fore Black -Back $ColorLookup[$Word];
                            Write-Host $after -NoNewline ;
                            $displayed = $true
                        }

                    }
                    If (-not $displayed) {
                        Write-Host "$Token " -NoNewline
                    } else {
                        Write-Host " " -NoNewline
                    }
                    $TotalLength = $TotalLength + $Token.Length + 1
                } else {
                    Write-Host '' #New Line
                    $TotalLength = 0

                }

            }
            Write-Host '' #New Line
        }
    }
    end {
    }
}


function Find-zxExecLocation {
    [CmdletBinding()]
    param(
        [string]$execName
    )

    $env:Path -split ';' | ForEach-Object { Get-ChildItem $_ $execName -ea 0 }
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
        [String]$ComputerName,
        [Switch]$UseFakeAdministratorCredential,
        [Switch]$UseSSL
    )

    if ($UseFakeAdministratorCredential) {
        if ($UseSSL) {
            $psSession = New-PSSession $ComputerName -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck) -Credential $credFakeAdministrator
        } else {
            $psSession = New-PSSession $ComputerName -Credential $credFakeAdministrator
        }
    } else {
        if ($UseSSL) {
            $psSession = New-PSSession $ComputerName -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck)
        } else {
            $psSession = New-PSSession $ComputerName
        }
    }

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
        git config --global http.proxy $xzProxy
        git clone $gitUrl
        Push-Location
        Set-Location ./$gitRepoName
        git config http.proxy $xzProxy
        Pop-Location
    } catch {
        Write-Host "Failed to clone $gitUrl" -ForegroundColor Red
    } finally {
        git config --global --unset http.proxy
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
    } catch {
        Write-Host "Failed to download $gitZipUrl" -ForegroundColor Red
    }

    Expand-Archive $gitRepoZipName
    Move-Item $gitLocalItem.FullName .
    Remove-Item $gitRepoName
    Rename-Item $gitLocalItem.Name $gitRepoName
    Remove-Item $gitRepoZipName
}


function Get-zxGitBranch {
    try {
        $gitBranch = git branch 2>$null
        if ($gitBranch) {
            return (( $gitBranch | Select-String '^\*' ) -split '\*' | Select-Object -Last 1).Trim()
        } else {
            return ''
        }
    } catch {
        return ''
    }

}

function Test-AdminMode {
    if ( 'S-1-5-32-544' -in [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value ) {
        return $true
    } else {
        return $false
    }
}


function Test-DebugMode {
    if (Test-Path -Path Variable:/PSDebugContext) {
        return $true
    } else {
        return $false
    }
}


function Get-zxPSVersion {
    $psVersionObject = $psVersionTable.PSVersion
    if ($psVersionObject.Major -lt 6) {
        $psVersion = "$($psVersionObject.Major).$($psVersionObject.Minor)"
    } elseIf ($psVersionObject.Major -ge 6) {
        $psVersion = $psVersionObject.ToString()
    }
    return $psVersion
}


function Get-CurrentPath {
    $currentPath = (Get-Location | ForEach-Object Path) -Split '::' | Select-Object -Last 1
    return $currentPath
}


function Test-LocalSession {
    if ($PSSenderInfo) {
        return $false
    }
    if (($env:TERM -match '^xterm') -and ($env:SSH_CONNECTION -ne $null)) {
        return $false
    }
    return $true
}


function Get-zxPythonVersion {
    return (python --version).Split()[1]
}


function Enable-Venv {
    Invoke-Expression "./venv/Scripts/activate.ps1"
}


function Update-Pip {
    Invoke-Expression "python -m pip install --upgrade pip"
}


$osVersion = Get-CimInstance Win32_OperatingSystem | ForEach-Object Caption
$lastRebootTime = (Get-CimInstance Win32_OperatingSystem | ForEach-Object LastBootUpTime).toString('yyyy-MM-dd HH:mm:ss')
Write-Host "$osVersion" -ForegroundColor Magenta
Write-Host "Last Reboot: $lastRebootTime" -ForegroundColor Magenta

$function:simpleprompt = { Write-Host "PS>" -ForegroundColor Cyan -NoNewline ; return ' ' }

$function:fullprompt = {
    $now = (Get-Date).toString("HH:mm:ss")
    # $gitBranch = Get-zxGitBranch
    Set-Variable -Name gitBranch -Value (Get-zxGitBranch) -Scope Script
    $psVersion = Get-zxPSVersion
    $pyVersion = Get-zxPythonVersion
    $path = Get-CurrentPath
    $isInLocalSession = Test-LocalSession
    $pythonVenvPath = $env:VIRTUAL_ENV
    $currentSecurityContextUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    Write-Host
    Write-Host "$now" -ForegroundColor Cyan -NoNewline

    if (Test-DebugMode) {
        Write-Host ' ' -NoNewline
        Write-Host '[DBG]' -ForegroundColor Black -BackgroundColor Yellow -NoNewline
    }

    if (Test-AdminMode) {
        Write-Host ' [admin] ' -ForegroundColor Red -NoNewline
    } else {
        Write-Host ' [user] ' -ForegroundColor DarkGray -NoNewline
    }

    if ($isInLocalSession) {
        Write-Host "$currentSecurityContextUserName @ $($env:COMPUTERNAME)" -ForegroundColor Magenta -NoNewline
    } else {
        Write-Host "$currentSecurityContextUserName @ $($env:COMPUTERNAME)" -ForegroundColor White -BackgroundColor DarkBlue -NoNewline
    }
    Write-Host " $path" -ForegroundColor Green -NoNewline
    Write-Host " [" -ForegroundColor Yellow -NoNewline
    Write-Host "$gitBranch" -ForegroundColor Cyan -NoNewline
    Write-Host "]" -ForegroundColor Yellow

    if ($pythonVenvPath) {
        Write-Host "venv:" -ForegroundColor Cyan -NoNewline
        Write-Host " $pythonVenvPath" -ForegroundColor DarkGray

    }

    if ($isInLocalSession) {
        # in local session
        Write-Host "ps.$psVersion | py.$pyVersion>" -ForegroundColor Cyan -NoNewline
        return ' '
    } else {
        # in PS remote session
        $backspaces = "`b" * ($zxPsComputerNameLength + 4)
        $lastPrompt = "$psVersion remote>"
        $remaningChars = [Math]::Max( ($zxPsComputerNameLength + 4) - $lastPrompt.Length, 0 )
        $tail = (" " * $remaningChars) + ("`b" * $remaningChars)
        return "${backspaces}${lastPrompt}${tail}"
    }

}

$function:prompt = $function:fullprompt

Set-Alias gh Get-Help
Set-Alias wh Write-Host
Set-Alias wo Write-Output
Set-Alias so Select-Object
Set-Alias os Out-String
Set-Alias ep Enter-PSSession
Set-Alias fromjson ConvertFrom-Json
Set-Alias tojson ConvertTo-Json
Set-Alias tnc Test-NetConnection
Set-Alias html Out-HtmlView

Set-Alias go Enter-zxPSSession
Set-Alias rdp Enter-zxRDPSession
Set-Alias cssh Enter-zxCyberArkSshSession
Set-Alias which Find-zxExecLocation
Set-Alias cgit Clone-zxGitRepo
Set-Alias dgit Download-zxGitRepo
Set-Alias scs Select-zxColorString
Set-Alias tw Trace-zxWord
Set-Alias tp Test-zxPort

Set-Alias vi vim
Set-Alias py python
Set-Alias ipy ipython
Set-Alias venv Enable-Venv
Set-Alias upip Update-Pip


if (Test-LocalSession) {
    $xzGit = 'D:\xiang\git\'
    if ($env:TERM_PROGRAM -ne 'vscode') {
        Set-Location $xzGit
    }

    Import-Module posh-git
    Import-Module oh-my-posh
    $ThemeSettings.MyThemesLocation = 'D:\xiang\git\PSScripts\PoshThemes\'
    $ThemeSettings.PromptSymbols.VirtualEnvSymbol = ''
    Set-Theme xiang-paradox
}
