$ModuleVersion = "1.0"
$ModuleName = "aModuleNameHere"
$ParentPath = "D:\xiang\Dropbox\Git"
$Path = Join-Path $ParentPath $ModuleName
$Author = "copdips"
$CompanyName = "contoso.com"
$Description = "$ModuleName PowerShell module"
$PowerShellVersion = $PSVersionTable.PSVersion.ToString()

# Create the module and private function directories
New-Item "$Path\$ModuleName" -ItemType Directory
New-Item "$Path\$ModuleName\Private" -ItemType Directory
New-Item "$Path\$ModuleName\Public" -ItemType Directory
New-Item "$Path\$ModuleName\Lib" -ItemType Directory
New-Item "$Path\$ModuleName\Bin" -ItemType Directory
New-Item "$Path\$ModuleName\en-US" -ItemType Directory # For about_Help files
New-Item "$Path\Tests" -ItemType Directory

#Create the module and related files
New-Item "$Path\$ModuleName.psm1" -ItemType File
New-Item "$Path\$ModuleName.Format.ps1xml" -ItemType File
New-Item "$Path\$ModuleName\en-US\about_$ModuleName.help.txt" -ItemType File
New-Item "$Path\Tests\$ModuleName.Tests.ps1" -ItemType File

$paramHash = @{
    ModuleVersion     = $ModuleVersion
    Path              = "$Path\$ModuleName.psd1"
    RootModule        = "$Path\$ModuleName.psm1"
    FormatsToProcess  = "$Path\$ModuleName.Format.ps1xml"
    Description       = $Description
    PowerShellVersion = $PowerShellVersion
    Author            = $Author
    CompanyName       = $CompanyName
}

New-ModuleManifest @paramHash
