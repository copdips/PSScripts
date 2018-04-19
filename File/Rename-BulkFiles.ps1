# https://blogs.technet.microsoft.com/heyscriptingguy/2013/11/22/use-powershell-to-rename-files-in-bulk/


$pattern = '\[nameToBeReplaced\].'
$filePath = 'D:\xiang\Videos'

PS C:\WINDOWS\system32> gci $filePath -File | Rename-Item -NewName {$_.name -replace $pattern,''} 