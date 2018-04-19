$ips = 1..255 | % {"192.168.111.$_"}

$t = $ips | % {(New-Object Net.NetworkInformation.Ping).SendPingAsync($_, 250)} ; [Threading.Tasks.Task]::WaitAll($t) ; $t.Result | Select Address, Status, RoundtripTime | ft -a