function Split-String {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Pattern = $(throw "$($MyInvocation.MyCommand.Name) : " `
                + "Cannot bind null or empty value to the parameter `"Pattern`""),

        [Parameter(
            ValueFromPipeline = $true,
            HelpMessage = "String or list of string to be splitted by the pattern")]
        [String[]]$Content
    )

    begin {
    }

    process {
        foreach ($line in $Content) {
            $line -split $Pattern
        }
    }

    end {
    }
}