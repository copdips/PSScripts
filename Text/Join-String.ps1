function Join-String {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Pattern = $(throw "$($MyInvocation.MyCommand.Name) : " `
                + "Cannot bind null or empty value to the parameter `"Pattern`""),

        [Parameter(
            Position = 1,
            ValueFromPipeline = $true,
            HelpMessage = "list of string to be joined by the pattern")]
        [String[]]$line
    )

    begin {
        $allLines = [System.Collections.Generic.List[String]]::new()
    }

    process {
        foreach ($myline in $line) {
            $allLines.Add($myline)
        }
    }

    end {
        $allLines -join $Pattern
    }
}