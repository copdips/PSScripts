Function Find-Word {
    # inspired by: https://ridicurious.com/2018/03/14/highlight-words-in-powershell-console/
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
