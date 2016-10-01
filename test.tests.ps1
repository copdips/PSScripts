$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
 
Describe "Test" {
 
#Shoud Be 比较结果是否一样，不区分大小写
Context "Should be test"{
    It "Add 1 and 2 is equal to 3" {
        add 1 2 | Should Be 3
    }
      It "Add -1 and 2 is not equal to 0" {
        add -1 2 | Should not Be 0
    }
}
 
#should be Exactly 比较结果是否一样，区分大小写
Context "Should BeExactly test"{
    It "HostName" {
        hostname | Should beexactly "DELL-ZX"
    }
 
}
 
#Should BeGreaterThan判断得到的结果是否比预定值大
Context "Should BeGreaterThan test"{
    It "PsVersion is above 3" {
        $PSVersionTable.PSVersion.Major | Should beGreaterThan 3
    }
 
}
 
#Should beoftype判断结果类型是否为指定类型
Context "Should beOfType test"{
    It "Get-ADUser type"{
        Get-aduser yli | Should beoftype Microsoft.ActiveDirectory.Management.ADUser
    }
 
}
 
#Should Exist判断文件是否存在
Context "Should Exist test"{
    It "C:\temp exist"{
        "c:\temp" | should exist
    }
      
}
 
 
#Should match 判断结果是否匹配正则表达式， 不区分大小写
 
Context "Should match test"{
    It "Find Email"{
        "jksjsjsjssdjs abc.xyz@yahoo.com hsosofs" | should match "[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
    }
      
}
 
 
#Should Throw 判断script block结果是否抛出异常
Context "Should Throw test" {
    It "Get a non-exist Process"{ 
     
        {Get-Process -Name "!@#$%&" -ErrorAction Stop} | Should Throw
    }
}
 
 
#Should BeNulorEmpty 判断结果是否为空
Context "Should BeNullorEmpty test"{
    It "Get something from test folder"{
     
        get-childitem C:\temp | should not benullorempty
    }
 
 
}
 
 
}