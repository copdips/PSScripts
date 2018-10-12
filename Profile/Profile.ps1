Set-Variable -Name PSProfilePath -Value $PSCommandPath -Option Constant

$fakeAdministratorPassword = "Password1" | ConvertTo-SecureString -asPlainText -Force
$fakeAdministratorName = "administrator"
$credFakeAdministrator = New-Object System.Management.Automation.PSCredential($fakeAdministratorName, $fakeAdministratorPassword)

(New-Object -TypeName System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$xiangProxy = ''
$env:PIP_PROXY = $xiangProxy

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


# Restore Powershell $env:PSModulePath when enter into Powershell from Pwsh
if ($PSVersionTable.PSVersion.Major -lt 6) {
    $currentPSModulePath = $env:PSModulePath
    $newPSModulePath = $currentPSModulePath -replace '\\Powershell\\', '\WindowsPowershell\'
    [System.Collections.ArrayList]$newPSModulePathArrayList = $newPSModulePath -split ';'
    $newPSModulePathArrayList.Insert(2, 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules')
    $env:PSModulePath = ($newPSModulePathArrayList | Select-Object -Unique) -join ';'
    Add-Type -TypeDefinition $typeIgnoreSslError
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

Set-PSReadlineOption -EditMode Emacs

#Python
$env:VIRTUAL_ENV_DISABLE_PROMPT = '1'


function Select-zxColorString {

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

        [Switch]$CaseSensitive = $false,

        [Parameter(
            ParameterSetName = 'NotMatch',
            HelpMessage = "If true, write only not matching lines; " `
                + "if false, write only matching lines")]
        [Switch]$NotMatch = $false,

        [Parameter(
            ParameterSetName = 'Match',
            HelpMessage = "If true, write all the lines; " `
                + "if false, write only matching lines")]
        [Switch]$KeepNotMatch = $false
    )

    begin {
        $paramSelectString = @{
            Pattern       = $Pattern
            AllMatches    = $true
            CaseSensitive = $CaseSensitive
        }
        $writeNotMatch = $KeepNotMatch -or $NotMatch
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

                        $paramWriteHost = @{
                            Object          = $line.Substring($myMatch.Index, $myMatch.Length)
                            NoNewline       = $true
                            ForegroundColor = $ForegroundColor
                            BackgroundColor = $BackgroundColor
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

        $Color = [enum]::GetNames([System.ConsoleColor]) | Where-Object {$_ -notin @('White', 'Black')}
        [array]::Reverse($Color) # personal preference to color with lighter/dull shades at the end

        $Counter = 0
        $ColorLookup = [ordered]@{}
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
                Where-Object {-not [string]::IsNullOrWhiteSpace($_)} |  #Filter-out whiteSpaces
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
        git config --global http.proxy $xiangProxy
        git clone $gitUrl
        Push-Location
        Set-Location ./$gitRepoName
        git config http.proxy $xiangProxy
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
            return (( $gitBranch | Select-String '^\*' ) -split '\*' |  Select-Object -Last 1).Trim()
        } else {
            return ''
        }
    } catch {
        return ''
    }

}

function Test-InPSSession {
    return $PSSenderInfo
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
        $psVersion = "$($psVersionObject.Major).$($psVersionObject.Minor).$($psVersionObject.Patch)"
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


$osVersion = Get-CimInstance Win32_OperatingSystem | ForEach-Object Caption
$lastRebootTime = (Get-CimInstance Win32_OperatingSystem | ForEach-Object LastBootUpTime).toString('yyyy-MM-dd HH:mm:ss')
Write-Host "$osVersion" -ForegroundColor Magenta
Write-Host "Last Reboot: $lastRebootTime" -ForegroundColor Magenta

$function:simpleprompt = {Write-Host "PS>" -ForegroundColor Cyan -NoNewline ; return ' '}

$function:fullprompt = {
    $now = (Get-Date).toString("HH:mm:ss")
    $gitBranch = Get-zxGitBranch
    $psVersion = Get-zxPSVersion
    $path = Get-CurrentPath
    $inPSSession = Test-InPSSession
    $pythonVenvPath = $env:VIRTUAL_ENV
    $currentSecurityContextUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    Write-Host
    Write-Host "$now" -ForegroundColor Cyan -NoNewline

    if (Test-DebugMode) {
        Write-Host ' ' -NoNewline
        Write-Host '[DBG]' -ForegroundColor Black -BackgroundColor Yellow -NoNewline
    }

    if (Test-AdminMode) {
        Write-Host ' [admin]' -ForegroundColor Red -NoNewline
    } else {
        Write-Host ' [user]' -ForegroundColor DarkGray -NoNewline
    }

    if ($inPSSession) {
        Write-Host " $currentSecurityContextUserName @ $($env:COMPUTERNAME) " -ForegroundColor White -BackgroundColor DarkBlue -NoNewline
    } else {
        Write-Host " $currentSecurityContextUserName @ $($env:COMPUTERNAME) " -ForegroundColor Magenta -NoNewline
    }
    Write-Host $path -ForegroundColor Green -NoNewline
    Write-Host " [" -ForegroundColor Yellow -NoNewline
    Write-Host "$gitBranch" -ForegroundColor Cyan -NoNewline
    Write-Host "]" -ForegroundColor Yellow

    if ($pythonVenvPath) {
        Write-Host "venv:" -ForegroundColor Cyan -NoNewline
        Write-Host " $pythonVenvPath" -ForegroundColor DarkGray

    }

    if (Test-LocalSession) {
        # in local session
        Write-Host "$psVersion>" -ForegroundColor Cyan -NoNewline
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

Set-Alias go Enter-zxPSSession
Set-Alias rdp Enter-zxRDPSession
Set-Alias cssh Enter-zxCyberArkSshSession
Set-Alias which Find-zxExecLocation
Set-Alias cgit Clone-zxGitRepo
Set-Alias dgit Download-zxGitRepo
Set-Alias scs Select-zxColorString
Set-Alias tw Trace-zxWord

Set-Alias vi D:\xiang\Dropbox\tools\system\vim80-586rt\vim\vim80\vim.exe
Set-Alias vim D:\xiang\Dropbox\tools\system\vim80-586rt\vim\vim80\vim.exe
Set-Alias putty D:\xiang\Dropbox\tools\network\Putty\putty.exe
Set-Alias ptpy ptpython


$xiangGit = 'D:\xiang\git\'
