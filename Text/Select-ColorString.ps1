function Select-ColorString {
    <#
    .SYNOPSIS

    Find the matches in a given content by the pattern and write the matches in color like grep

    .NOTES

    inspired by: https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString a

    Both line 'aa bb cc' and line 'A line' are displayed as both contain "a" case insensitive

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString a -NotMatch

    Nothing will be displayed as both lines have "a"

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString a -CaseSensitive

    Only line 'aa bb cc' is displayed with color on all occurrences of "a" case sensitive

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString '(a)|(\sb)' -CaseSensitive -BackgroundColor White

    Only line 'aa bb cc' is displayed with background color White on all occurrences of regex '(a)|(\sb)' case sensitive

    .EXAMPLE

    > 'aa bb cc', 'A line' | Select-ColorString b -KeepNotMatch

    Both line 'aa bb cc' and 'A line' are displayed with color on all occurrences of "b" case insensitive,
    and for lines without the keyword "b", they will be only displayed but without color

    .EXAMPLE

    > Get-Content "C:\Windows\Logs\DISM\dism.log" -Tail 100 -Wait | Select-ColorString win

    Find and color the keyword "win" in the last ongoing 100 lines of dism.log

    .EXAMPLE

    > Get-WinEvent -FilterHashtable @{logname='System'; StartTime = (Get-Date).AddDays(-1)} | Select-Object time*,level*,message | Select-ColorString win

    Find and color the keyword "win" in the System event log from the last 24 hours
    #>

    [Cmdletbinding(DefaultParametersetName = 'Match')]
    Param(
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
                }
                else {
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
            }
            else {
                if ($writeNotMatch) {
                    Write-Host "$line"
                }
            }
        }
    }

    end {
    }
}
