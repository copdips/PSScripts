
# This script should be run under as administrator over Powershell native version (not WoW)

# Ref : https://technet.microsoft.com/en-us/windows-server-docs/get-started/getting-started-with-nano-server
# Ref : https://technet.microsoft.com/en-us/windows-server-docs/get-started/nano-server-quick-start
# Ref : https://technet.microsoft.com/en-us/windows-server-docs/get-started/deploy-nano-server


$imagePath = "D:\xiang\iso\Windows Server 2016\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO"

$imageDriveLetter = (Get-DiskImage -ImagePath $imagePath | Get-Volume).DriveLetter

if (-not $imageDriveLetter) { 
    $imageDriveLetter = Mount-DiskImage $imagePath -PassThru | Get-Volume |  select -exp DriveLetter
}

Import-Module "$($imageDriveLetter):\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator" -Verbose

$pass = Read-Host "Enter Password" -AsSecureString

$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList Administrator, $pass


# Ensure you have the lastest version of DSIM
# To service this Windows image requires the latest version of the DISM. See http://go.microsoft.com/fwlink/?LinkId=293395 to find the latest version of DISM, 
# and http://go.microsoft.com/fwlink/?LinkId=293394 to learn how to install the latest version of DISM from the ADK on your computer.

# Workgroup
New-NanoServerImage -Edition Datacenter -DeploymentType Guest -MediaPath "$($imageDriveLetter):" -BasePath D:\xiang\Hyper-V\16NANO02\Base -TargetPath D:\xiang\Hyper-V\16NANO02\16NANO02.vhd -ComputerName 16NANO02 -AdministratorPassword $pass -Ipv4Address 192.168.111.162 -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 192.168.111.1 -Ipv4Dns 192.168.111.201 -InterfaceNameOrIndex Ethernet -EnableRemoteManagementPort -SetupCompleteCommands @("tzutil.exe /s ""Romance Standard Time""")

# Domain offline join (djoin), you shoud better run this command from a computer that is already in the domain, otherwise you need to in advance harvest the blob from another computer in domain
# https://technet.microsoft.com/en-us/windows-server-docs/get-started/deploy-nano-server#joining-domains
# New-NanoServerImage -Edition Datacenter -DeploymentType Guest -MediaPath "$($imageDriveLetter):" -BasePath D:\xiang\Hyper-V\16NANO02\Base -TargetPath D:\xiang\Hyper-V\16NANO02\16NANO02.vhd -ComputerName 16NANO02 -AdministratorPassword $pass -Ipv4Address 192.168.111.162 -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 192.168.111.1 -Ipv4Dns 192.168.111.201 -InterfaceNameOrIndex Ethernet -EnableRemoteManagementPort -DomainName contoso.com
New-NanoServerImage -Edition Datacenter -DeploymentType Guest -MediaPath "$($imageDriveLetter):" -BasePath D:\xiang\Hyper-V\16NANO02\Base -TargetPath D:\xiang\Hyper-V\16NANO02\16NANO02.vhd -AdministratorPassword $pass -Ipv4Address 192.168.111.162 -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 192.168.111.1 -Ipv4Dns 192.168.111.201 -InterfaceNameOrIndex Ethernet -EnableRemoteManagementPort -DomainBlobPath D:\xiang\Hyper-V\16NANO02\16NANO02.djoin -SetupCompleteCommands @("tzutil.exe /s ""Romance Standard Time""")

# add KB and vmware driver too.
# https://blogs.technet.microsoft.com/nanoserver/2016/10/07/updating-nano-server/
# http://www.v-front.de/2016/07/how-to-deploy-windows-nano-server-tp5.html


New-VM -Name 16NANO02 -MemoryStartupBytes 2048MB -SwitchName 'External VM Switch' -VHDPath 'D:\xiang\Hyper-V\16NANO02\16NANO02.vhd' -Path 'D:\xiang\Hyper-V\16NANO02\' -Generation 1

Start-VM -Name 16NANO02

Enter-PSSession 192.168.111.162 -Credential $cred

gip

# 16NANO01 with Containers and Computer
New-NanoServerImage -Edition Datacenter -DeploymentType Guest -MediaPath "$($imageDriveLetter):" -BasePath D:\xiang\Hyper-V\16NANO01\Base -TargetPath D:\xiang\Hyper-V\16NANO01\16NANO01.vhd -AdministratorPassword $pass -Ipv4Address 192.168.111.161 -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 192.168.111.1 -Ipv4Dns 192.168.111.201 -InterfaceNameOrIndex Ethernet -EnableRemoteManagementPort -DomainBlobPath D:\xiang\Hyper-V\16NANO01\16NANO01.djoin -Containers -Compute

New-VM -Name 16NANO01 -MemoryStartupBytes 2048MB -SwitchName 'External VM Switch' -VHDPath 'D:\xiang\Hyper-V\16NANO01\16NANO01.vhd' -Path 'D:\xiang\Hyper-V\16NANO01\' -Generation 1

Start-VM -Name 16NANO01

Enter-PSSession 192.168.111.161 -Credential $cred

# Docker
# https://blog.docker.com/2016/09/build-your-first-docker-windows-server-container/
# https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_server
# https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start
Install-PackageProvider nuget

Install-Module DockerMsftProvider -Force -Verbose
# [16NANO01]: PS C:\Users\Administrator\Documents> install-module dockermsftprovider -force -Verbose
# VERBOSE: Using the provider 'PowerShellGet' for searching packages.
# VERBOSE: The -Repository parameter was not specified.  PowerShellGet will use all of the registered repositories.
# VERBOSE: Getting the provider object for the PackageManagement Provider 'NuGet'.
# VERBOSE: The specified Location is 'https://www.powershellgallery.com/api/v2/' and PackageManagementProvider is
# 'NuGet'.
# VERBOSE: Searching repository 'https://www.powershellgallery.com/api/v2/FindPackagesById()?id='dockermsftprovider'' for
#  ''.
# VERBOSE: Total package yield:'1' for the specified package 'dockermsftprovider'.
# VERBOSE: Performing the operation "Install-Module" on target "Version '1.0.0.1' of module 'DockerMsftProvider'".
# VERBOSE: The installation scope is specified to be 'AllUsers'.
# VERBOSE: The specified module will be installed in 'C:\Program Files\WindowsPowerShell\Modules'.
# VERBOSE: The specified Location is 'NuGet' and PackageManagementProvider is 'NuGet'.
# VERBOSE: Downloading module 'DockerMsftProvider' with version '1.0.0.1' from the repository
# 'https://www.powershellgallery.com/api/v2/'.
# VERBOSE: Searching repository 'https://www.powershellgallery.com/api/v2/FindPackagesById()?id='DockerMsftProvider'' for
#  ''.
# VERBOSE: InstallPackage' - name='DockerMsftProvider',
# version='1.0.0.1',destination='C:\Users\Administrator\AppData\Local\Temp\1944563314'
# VERBOSE: DownloadPackage' - name='DockerMsftProvider',
# version='1.0.0.1',destination='C:\Users\Administrator\AppData\Local\Temp\1944563314\DockerMsftProvider\DockerMsftProvid
# er.nupkg', uri='https://www.powershellgallery.com/api/v2/package/DockerMsftProvider/1.0.0.1'
# VERBOSE: Downloading 'https://www.powershellgallery.com/api/v2/package/DockerMsftProvider/1.0.0.1'.
# VERBOSE: Completed downloading 'https://www.powershellgallery.com/api/v2/package/DockerMsftProvider/1.0.0.1'.
# VERBOSE: Completed downloading 'DockerMsftProvider'.
# VERBOSE: InstallPackageLocal' - name='DockerMsftProvider',
# version='1.0.0.1',destination='C:\Users\Administrator\AppData\Local\Temp\1944563314'
# VERBOSE: Catalog file 'DockerMsftProvider.cat' is not found in the contents of the module 'DockerMsftProvider' being
# installed.
# VERBOSE: For publisher validation, using the previously-installed module 'DockerMsftProvider' with version '1.0.0.1'
# under 'C:\Program Files\WindowsPowerShell\Modules\DockerMsftProvider\1.0.0.1' with publisher name ''. Is this module
# signed by Microsoft: 'False'.
# VERBOSE: Module 'DockerMsftProvider' was installed successfully to path 'C:\Program
# Files\WindowsPowerShell\Modules\DockerMsftProvider\1.0.0.1'.

Install-Package -Name docker -ProviderName DockerMsftProvider -Force -Verbose

# [16NANO01]: PS C:\Users\Administrator\Documents> Install-Package -Name docker -ProviderName DockerMsftProvider -Force -Verbose
# VERBOSE: Importing package provider 'DockerMsftProvider'.
# VERBOSE: Using the provider 'DockerMsftProvider' for searching packages.
# VERBOSE: Download size: 0MB
# VERBOSE: Free space on the drive: 2923.08MB
# VERBOSE: Downloading https://dockermsft.blob.core.windows.net/dockercontainer/DockerMsftIndex.json to
# C:\Users\ADMINI~1\AppData\Local\Temp\DockerMsftProvider\DockerDefault_DockerSearchIndex.json
# VERBOSE: About to download
# VERBOSE: Finished downloading
# VERBOSE: Downloaded in 0 hours, 0 minutes, 1 seconds.
# VERBOSE: Performing the operation "Install Package" on target "Package 'Docker' version '1.12.2-cs2-ws-beta' from
# 'DockerDefault'.".
# WARNING: KB3176936 or later is required for docker to work. Please ensure this is installed.
# VERBOSE: Containers package is already installed. Skipping the install.
# VERBOSE: Download size: 13.53MB
# VERBOSE: Free space on the drive: 2921.05MB
# VERBOSE: Downloading https://dockermsft.blob.core.windows.net/dockercontainer/docker-1-12-2-cs2-ws-beta.zip to
# C:\Users\ADMINI~1\AppData\Local\Temp\DockerMsftProvider\Docker-1-12-2-cs2-ws-beta.zip
# VERBOSE: About to download
# VERBOSE: Finished downloading
# VERBOSE: Downloaded in 0 hours, 0 minutes, 14 seconds.
# VERBOSE: Verifying Hash of the downloaded file.
# VERBOSE: Hash verified!
# VERBOSE: Found C:\Users\ADMINI~1\AppData\Local\Temp\DockerMsftProvider\Docker-1-12-2-cs2-ws-beta.zip to install.
# VERBOSE: Trying to unzip : C:\Users\ADMINI~1\AppData\Local\Temp\DockerMsftProvider\Docker-1-12-2-cs2-ws-beta.zip
# VERBOSE: Preparing to expand...
# VERBOSE: Created 'C:\Program Files\docker\docker.exe'.
# VERBOSE: Created 'C:\Program Files\docker\dockerd.exe'.
# VERBOSE: Trying to enable the docker service...
# VERBOSE: Removing the archive: C:\Users\ADMINI~1\AppData\Local\Temp\DockerMsftProvider\Docker-1-12-2-cs2-ws-beta.zip
# WARNING: A restart is required to start docker service. Please restart your machine.
# WARNING: After the restart please start the docker service.

# Name                           Version          Source           Summary
# ----                           -------          ------           -------
# Docker                         1.12.2-cs2-ws... DockerDefault    Contains the CS Docker Engine for use with Windows ...

Restart-Computer -Force ; exit

# WARNING: KB3176936 or later is required for docker to work. Please ensure this is installed.
# https://blogs.technet.microsoft.com/nanoserver/2016/10/07/updating-nano-server/
# http://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB3176936
expand C:\temp\kb3176936.msu -F:* C:\temp\kb3176936

# Install kb3176936 on 2016 core & desktop :
# https://github.com/Microsoft/Virtualization-Documentation/pull/390/files
# Online update : Run sconfig, then choose option 6 and then A and A to install all updates.
# Offiline update : http://www.catalog.update.microsoft.com/Search.aspx?q=KB3176936

# https://stefanscherer.github.io/run-linux-and-windows-containers-on-windows-10/
# https://blog.docker.com/2016/09/build-your-first-docker-windows-server-container/
# https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start
# https://docs.docker.com/docker-for-windows/

# https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_10
Invoke-WebRequest "https://test.docker.com/builds/Windows/x86_64/docker-1.13.0-rc2.zip" -OutFile "$env:TEMP\docker-1.13.0-rc2.zip" -UseBasicParsing
Expand-Archive -Path "$env:TEMP\docker-1.13.0-rc2.zip" -DestinationPath $env:ProgramFiles
# For quick use, does not require shell to be restarted.
$env:path += ";c:\program files\docker"
# For persistent use, will apply even after a reboot.
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Docker", [EnvironmentVariableTarget]::Machine)
or:
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH �CValue $($env:Path + ";C:\Program Files\Docker")
or:
$env:path += ";C:\Program Files\Docker"
setx PATH $env:path /M


dockerd --register-service
Start-Service Docker  # This will create the fodler C:\ProgramData\docker

# Configure Docker Daemon
# Pour ce faire, un ficher daemon.json dans c :\ProgramData\docker\config
# https://msdn.microsoft.com/en-us/virtualization/windowscontainers/docker/configure_docker_daemon
{
    "hosts": ["tcp://0.0.0.0:2376", "npipe://"]
}

# Restart docker service
Restart-Service docker

docker pull microsoft/nanoserver
docker images
docker run -it microsoft/nanoserver cmd
powershell.exe Add-Content C:\helloworld.ps1 'Write-Host "Hello World"'
exit
docker ps -a

docker run microsoft/dotnet-samples:dotnetapp-nanoserver

docker pull microsoft/windowsservercore
docker run microsoft/windowsservercore hostname


# To change the timezone
# tzutil
Paris : tzutil /s "Romance Standard Time"

cmd /c w32tm /config /syncfromflags:domhier /update && w32tm /resync 
HKLM\SYSTEM\CurrentControlSet\Services\w32time\Parameters 
Type = NT5DS

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\w32time\Parameters" -Name Type -Value "NT5DS"


# WinRM kerberos token
gp "HKLM:\SYSTEM\CurrentControlSet\services\HTTP\Parameters"
gci "HKLM:\SYSTEM\CurrentControlSet\services\HTTP\"

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\HTTP\Parameters" -Name MaxFieldLength -Value 65534

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\HTTP\Parameters" -Name MaxRequestBytes -Value 16777216

# nano on ESXi
# http://www.v-front.de/2016/07/how-to-deploy-windows-nano-server-tp5.html

# Disbale firewall
netsh advfirewall set allprofiles state off


# install docker manually
# https://msdn.microsoft.com/en-us/virtualization/windowscontainers/docker/configure_docker_daemon?f=255&MSPPError=-2147217396
# https://github.com/docker/labs/blob/master/windows/windows-containers/Setup-Server2016.md


Get-FileHash $imagePath


$credContoso = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList Contoso\Xiang, (ConvertTo-SecureString -String "Password1" -AsPlainText) -Force)

Enter-PSSession 192.168.111.161 -Credential $credContoso

# Keyboard
# Doesn't work as need International PsModule : Set-WinUserLanguageList -LanguageList fr-fr
# Nano with unattendfile : https://social.technet.microsoft.com/Forums/en-US/d3554b6d-5539-40da-bd1a-c728e30e0158/changing-regional-settings-on-nano-server?forum=NanoServer

# Get event log 
# Nano doesn't have Get-EventLog, but have Get-WiEvent and Win32_NTLogEvent
Get-CimInstance Win32_NTLogEvent -Filter 'LogFile="System" and Type="Error"' | Select-Object EventCode,InsertionStrings,Message,RecordNumber,SourceName,TimeGenerated,TimeWritten,Type,User | Export-Csv -NoTypeInformation -NoClobber -Path C:\SystemEventErrors.csv 

# Expand Disk, C:\ for example
# Run as Administrator elevated
$MaxSize = (Get-PartitionSupportedSize -DriveLetter c).sizeMax
Resize-Partition -DriveLetter c -Size $MaxSize
#By Diskpart
"rescan","select volume 2","extend" | diskpart
