function Select-ColorString {
    <#
    .SYNOPSIS

    Find the matches in a given content by the pattern and write the matches in color like grep

    .NOTES

    inspired by: https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/

    .DESCRIPTION

    Find the matches in a given content by the pattern and write the matches in color like grep

    DYNAMIC PARAMETERS
    -ForegroundColor <String>
        The foreground color to highlight the string matching the pattern.
        The default value is "Black".

    -BackgroundColor <String>
        The background color to highlight the string matching the pattern.
        The default value is "Yellow".


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

    > Get-Content "C:\Windows\Logs\DISM\dism.log" -Tail 100 | Select-ColorString win

    Find and color the keyword "win" in the last 100 lines of dism.log

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

    DynamicParam {
        $foregroundColorParamName = 'ForegroundColor'
        $backgroundColorParamName = 'BackgroundColor'

        $basicAttributes = New-Object System.Management.Automation.ParameterAttribute
        $basicAttributes.ParameterSetName = "__AllParameterSets"
        $basicAttributes.Mandatory = $false

        $colorlist = [enum]::GetNames([System.ConsoleColor])
        $validationset = New-Object -Type System.Management.Automation.ValidateSetAttribute -ArgumentList $colorlist

        $backgroundColorValidateScript = {
            if ($Host.ui.RawUI.BackgroundColor -eq $_) {
                throw "Current host background color is also set to `"$_`", " `
                    + "please choose another color for a better readability"
            }
            else {
                return $true
            }
        }
        $validationScript = New-Object -Type System.Management.Automation.ValidateScriptAttribute -ArgumentList $backgroundColorValidateScript

        $foregroundColorCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $foregroundColorAttributes = $basicAttributes
        $foregroundColorCollection.Add($foregroundColorAttributes)
        $foregroundColorCollection.Add($validationset)

        $backgroundColorCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $backgroundColorAttributes = $basicAttributes
        $backgroundColorCollection.Add($backgroundColorAttributes)
        $backgroundColorCollection.Add($validationset)
        $backgroundColorCollection.Add($validationScript)

        $foreground = New-Object -Type System.Management.Automation.RuntimeDefinedParameter($foregroundColorParamName, [String], $foregroundColorCollection)
        $background = New-Object -Type System.Management.Automation.RuntimeDefinedParameter($backgroundColorParamName, [String], $backgroundColorCollection)

        $PSBoundParameters[$foregroundColorParamName] = 'Black'
        $PSBoundParameters[$backgroundColorParamName] = 'Yellow'

        $dynamicParams = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $dynamicParams.Add($foregroundColorParamName, $foreground)
        $dynamicParams.Add($backgroundColorParamName, $background)

        return $dynamicParams
    }

    begin {
        $foregroundColor = $PsBoundParameters[$foregroundColorParamName]
        $backgroundColor = $PsBoundParameters[$backgroundColorParamName]
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
                            ForegroundColor = $foregroundColor
                            BackgroundColor = $backgroundColor
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
