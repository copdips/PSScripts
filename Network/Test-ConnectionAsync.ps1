Function Test-ConnectionAsync {
    <#
        .SYNOPSIS
            Performs a ping test asynchronously

        .DESCRIPTION
            Performs a ping test asynchronously

        .PARAMETER Computername
            List of computers to test connection

        .PARAMETER Timeout
            Timeout in milliseconds

        .PARAMETER TimeToLive
            Sets a time to live on ping request

        .PARAMETER Fragment
            Tells whether to fragment the request

        .PARAMETER Buffer
            Supply a byte buffer in request

        .NOTES
            Name: Test-ConnectionAsync
            Author: Boe Prox
            Version History:
                1.0 //Boe Prox - 12/24/2015
                    - Initial result

        .OUTPUT
            Net.AsyncPingResult

        .EXAMPLE
            Test-ConnectionAsync -Computername server1,server2,server3

            Computername                Result
            ------------                ------
            Server1                     Success
            Server2                     TimedOut
            Server3                     No such host is known

            Description
            -----------
            Performs asynchronous ping test against listed systems.
    #>
    #Requires -Version 3.0
    [OutputType('Net.AsyncPingResult')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True)]
        [string[]]$Computername,
        [parameter()]
        [int32]$Timeout = 100,
        [parameter()]
        [Alias('Ttl')]
        [int32]$TimeToLive = 128,
        [parameter()]
        [switch]$Fragment,
        [parameter()]
        [byte[]]$Buffer
    )
    Begin {

        If (-NOT $PSBoundParameters.ContainsKey('Buffer')) {
            $Buffer = 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
            0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69
        }
        $PingOptions = New-Object System.Net.NetworkInformation.PingOptions
        $PingOptions.Ttl = $TimeToLive
        If (-NOT $PSBoundParameters.ContainsKey('Fragment')) {
            $Fragment = $False
        }
        $PingOptions.DontFragment = $Fragment
        $computerList = New-Object System.Collections.ArrayList
        If ($PSBoundParameters.ContainsKey('Computername')) {
            [void]$computerList.AddRange($Computername)
        } Else {
            $IsPipeline = $True
        }
    }
    Process {
        If ($IsPipeline) {
            [void]$computerList.Add($Computername)
        }
    }
    End {
        $Task = ForEach ($myComputer in $computerList) {
            [PSCustomObject] @{
                Computername = $myComputer
                Task = (New-Object System.Net.NetworkInformation.Ping).SendPingAsync($myComputer,$Timeout, $Buffer, $PingOptions)
            }
        }
        Try {
            [void][Threading.Tasks.Task]::WaitAll($Task.Task)
        } Catch {}
        $Task | ForEach-Object {
            If ($_.Task.IsFaulted) {
                $Result = $_.Task.Exception.InnerException.InnerException.Message
                $IPAddress = $Null
            } Else {
                $Result = $_.Task.Result.Status
                $IPAddress = $_.task.Result.Address.ToString()
            }
            $Object = [PSCustomObject]@{
                Computername = $_.Computername
                IPAddress = $IPAddress
                Result = $Result
            }
            $Object.PSTypeNames.Insert(0, 'Net.AsyncPingResult')
            $Object
        }
    }

}