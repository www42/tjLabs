$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList "administrator",(ConvertTo-SecureString  $LabPw -AsPlainText -Force)

$Host1 = New-PSSession -VMName "Docker-Host1" -Credential $Cred
$Host2 = New-PSSession -VMName "Docker-Host2" -Credential $Cred
$Host3 = New-PSSession -VMName "Docker-Host3" -Credential $Cred

Enter-PSSession $Host1
#---------------------

Install-PackageProvider nuget -Force
Find-PackageProvider DockerMsftProvider | Install-PackageProvider -Force
Find-Package -Provider DockerMsftProvider

# Status quo ante
Get-WindowsFeature -Name Containers
Get-WindowsFeature -Name Hyper-V,Hyper-V-PowerShell
Get-Module -ListAvailable -Name Hyper-V
Get-VMSwitch
Get-Service Docker
Get-Command docker
Get-Command dockerd

# Installation Docker
Install-Package -Name "Docker" -Provider "DockerMsftProvider" -Force
Restart-Computer -Force

# Status quo
#    wie oben

Get-Module -ListAvailable -Name Containers
Get-Command -Module Containers
Get-ContainerNetwork
Get-NetNat


Start-Process -FilePath "https://docs.microsoft.com/de-de/virtualization/windowscontainers/quick-start/using-insider-container-images"

Enter-PSSession $Host2    # Windows Server Insider
#-------------------------------------------------
Install-PackageProvider "NuGet" -Force
Find-PackageProvider -Name "DockerProvider" | Install-PackageProvider -Force
Find-Package -Provider "DockerProvider"
#   17.06.2-EE    :-((
Find-Package -Provider "DockerProvider" -RequiredVersion Preview
#   17.10.0-EE    :-(