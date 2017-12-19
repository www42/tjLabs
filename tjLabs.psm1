function PublishToMyGet-Module {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true,Position=1)][string]$ModuleName
  )

  Get-PSRepository | ft Name,SourceLocation,PublishLocation
  
  $PathDefault = "C:\Git\$ModuleName"
  [string]$PathToModule = Read-Host -Prompt "Path to module  [$PathDefault]"
  if ([string]::IsNullOrEmpty($PathToModule)) {$PathToModule = $PathDefault}

  $RepoDefault = "MyGet"
  [string]$Repo = Read-Host -Prompt "Repo  [$RepoDefault]"
  if ([string]::IsNullOrEmpty($Repo)) {$Repo = $RepoDefault}

  $NuGetApiKey = Read-Host -Prompt "NuGetApiKey" 

  $PathTemp = "$PathToModule\temp\$ModuleName"
  mkdir $PathTemp | Out-Null
  copy "$PathToModule\$ModuleName.psm1" $PathTemp
  copy "$PathToModule\$ModuleName.psd1" $PathTemp
 
  Publish-Module -Path $PathTemp -Repository $Repo -NuGetApiKey $NuGetApiKey

  Remove-Item -Path "$PathToModule\temp" -Recurse -Force
}

function ConvertTo-VmComputerName {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true,Position=1)][string]$VmName
  )
  $VmComputerName = $VmName.split("-",2)[1]
  Write-Output $VmComputerName
}
function ConvertTo-VmName {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1)][string]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
  )
  $VmName = "$Lab-$VmComputerName"
  Write-Output $VmName
}

function New-Lab {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$false,Position=1)][string]$Dir    = $Global:LabDir,
  [Parameter(Mandatory=$false,Position=2)][string]$Switch = $Global:LabSwitch
  )
# create LabDir
if (Test-Path -Path $Dir){Write-Output $('$LabDir  ' + $Dir + '  already exists. Nothing to do.')}
else { mkdir $Dir }

# create LabSwitch
if (Get-VMSwitch -Name $Switch -ErrorAction SilentlyContinue) {Write-Output $('$LabSwitch  ' + $Switch + '  already exists. Nothing to do.')}
else { New-VMSwitch -Name $Switch -SwitchType Internal }

# create LabRouter
 # todo
}

function Get-LabVm {
  [CmdletBinding()]Param(
[Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
[Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
)
  Begin {}
  Process {
  foreach ($VmComp in $VmComputerName){
    $VmName = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
    Get-VM -Name $VmName | Select-Object -Property *,@{n="VmComputerName";e={$VmComp}}
  }
}
  End {}
}
function Get-Lab {
  <#
.SYNOPSIS
	List all virtual machines of a Lab.
.DESCRIPTION
	List all virtual machines of a Lab.
.PARAMETER Lab
	The name of the Lab.
.EXAMPLE
	Get-Lab -Lab 21410D
#>
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$false,Position=1)][string]$Lab=$Global:Lab
  )
  
  $LabVms = Get-LabVm -VmComputerName '*' -Lab $Lab
  foreach ($LabVm in $LabVms) {
  $VmName = $LabVm.Name
  $VmComputerName = ConvertTo-VmComputerName -VmName $VmName
  Get-LabVm -VmComputerName $VmComputerName
  }
}

function Show-LabVm {
  [CmdletBinding()]Param (
[Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
[Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
)
  Begin {}
  Process {
Get-LabVm -VmComputerName $VmComputerName -Lab $Lab |
    Sort-Object -Property name |
    Format-Table -AutoSize `
                -Property name,`
                          @{e={$_.state};l="State";a="left"},`
                          @{e={$_.generation};l="Gen"},`
                          @{e={$_.version};l="Ver"},`
                          @{e={$_.memoryassigned/1MB};l="Mem(MB)"},`
                          @{e={$_.processorcount};l="CPUs"},`
                          @{e={($_.networkadapters).switchname};l="Switch"},`
                          @{e={($_.networkadapters).ipaddresses| foreach {if ($_ -notlike "fe80*") {$_}}};l="IP Addresses"}
}
  End {}
}
function Show-Lab {
  <#
.SYNOPSIS
	List all virtual machines of a Lab.
.DESCRIPTION
	List all virtual machines of a Lab.
.PARAMETER Lab
	The name of the Lab.
.EXAMPLE
	Get-Lab -Lab 21410D
#>
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$false,Position=1)][string]$Lab=$Global:Lab
  )
  
  $LabUpper = ($Lab).ToUpper()
  Write-Output " "
  Write-Output "VMs in Lab ${LabUpper}:"
  
  Show-LabVm -VmComputerName '*' -Lab $Lab
}
New-Alias -Name shl -Value Show-Lab

function Start-LabVm {
  <#
.SYNOPSIS
	Starts a virtual machine.
.DESCRIPTION
		Starts a virtual machine.
.PARAMETER ComputerName
	The computer name inside the virtual machine.
.PARAMETER Lab
	The name of the lab. A lab is a collection of Virtual machines starting with the same prefix.
.EXAMPLE
	Start-LabVm -ComputerName LON-DC1 -Lab 21410D
#>
  [CmdletBinding()]Param (
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
  )
  Begin {}
  Process {
  foreach ($VmComp in $VmComputerName){
    $VmName = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
    Start-VM -Name $VmName 
  }
}
  End {}
}
# There is no "Start-Lab" by intention.

function Stop-LabVm {
  <#
.SYNOPSIS
	Stops a virtual machine.
.DESCRIPTION
		Stops a virtual machine.
.PARAMETER ComputerName
	The computer name inside the virtual machine.
.PARAMETER Lab
	The name of the lab. A lab is a collection of Virtual machines starting with the same prefix.
.EXAMPLE
	Stop-LabVm -ComputerName LON-DC1 -Lab 21410D
#>
  [CmdletBinding()]Param (
[Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
[Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
)
  Begin {}
  Process {
  foreach ($VmComp in $VmComputerName){  
    $VmName = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
    Stop-VM -Name $VmName
  }
}
  End {}
}
function Stop-Lab {
  <#
.SYNOPSIS
	Stops all running virtual machines of a Lab.
.DESCRIPTION
	Stops all running virtual machines of a Lab.
.PARAMETER Lab
	The name of the Lab.
.EXAMPLE
	Stop-Lab -Lab 21410D
#>
  [CmdletBinding()]Param(
[Parameter(Mandatory=$false,Position=1)][string]$Lab=$Global:Lab
)
  Get-Lab -Lab $Lab | where state -EQ "Running" | 
      foreach {
       $VmName = $_.Name
       $VmComputerName = ConvertTo-VmComputerName -VmName $VmName
       Stop-LabVm -VmComputerName $VmComputerName -Lab $Lab
    }
}

function Checkpoint-LabVm {
  [CmdletBinding()]Param (
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$true ,Position=2)][string]$Description,
  [Parameter(Mandatory=$false,Position=3)][string]$Lab = $Global:Lab
  )
  Begin {
#$De = New-Object -TypeName System.Globalization.CultureInfo("de-DE")
#$Datum = Get-Date -Format ($De.DateTimeFormat.FullDateTimePattern)
#$SnapshotName = "$Description - $Datum"
$SnapshotName = $Description
}
  Process {
  foreach ($VmComp in $VmComputerName){  
    $VmName = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
    Checkpoint-VM -Name $VmName -SnapshotName $SnapshotName
  }
}
  End {}
}
function Checkpoint-Lab {
  [CmdletBinding()]Param(
[Parameter(Mandatory=$true, Position=1)][string]$Description,
[Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
)
  Get-Lab -Lab $Lab |
      foreach {
      $VmName = $_.Name
      $VmComputerName = ConvertTo-VmComputerName -VmName $VmName
      Checkpoint-LabVm -VmComputerName $VmComputerName -Description $Description -Lab $Lab
    }
}

function New-LabVmGen1 {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)]                        [string]  $Lab      = $Global:Lab,    
  [Parameter(Mandatory=$false,Position=3)]                        [string]  $Dir      = $Global:LabDir,
  [Parameter(Mandatory=$false,Position=4)]                        [string]  $Switch   = $Global:LabSwitch,
  [Parameter(Mandatory=$false,Position=5)]                        [long]    $Mem      = $Global:LabVmMem,
  [Parameter(Mandatory=$false,Position=6)]                        [long]    $Count    = $Global:LabVmCpuCount,
  [Parameter(Mandatory=$false,Position=7)]                        [string]  $Version  = $Global:LabVmVersion
  )
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $VmDir   = Join-Path $Dir $VmName
     $VhdDir  = Join-Path $VmDir  "Virtual Hard Disks"
     $VhdPath = Join-Path $VhdDir "$VmName.vhd"                    # vhd   (ohne x, da Generation 1)
     New-Item -Path $VhdDir -ItemType Directory | Out-Null
     New-VHD -Path $VhdPath -Dynamic -SizeBytes 127GB | Out-Null
     New-VM -Name $VmName -Path $Dir -VHDPath $VhdPath -MemoryStartupBytes $Mem -SwitchName $Switch -Version $Version | Out-Null
     Set-VM -Name $VmName -ProcessorCount $Count
    }
}
  End {}
}
function New-LabVmGen1Differencing {
  [CmdletBinding()]Param(
[Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true)][string[]]$VmComputerName,
[Parameter(Mandatory=$false,Position=2)]                        [string]  $Lab      = $Global:Lab,    
[Parameter(Mandatory=$false,Position=3)]                        [string]  $Dir      = $Global:LabDir,
[Parameter(Mandatory=$false,Position=4)]                        [string]  $Switch   = $Global:LabSwitch,
[Parameter(Mandatory=$false,Position=5)]                        [long]    $Mem      = $Global:LabVmMem,
[Parameter(Mandatory=$false,Position=6)]                        [long]    $Count    = $Global:LabVmCpuCount,
[Parameter(Mandatory=$false,Position=7)]                        [string]  $Version  = $Global:LabVmVersion,
[Parameter(Mandatory=$false,Position=8)]                        [string]  $BaseVhd  = $Global:LabBaseGen1
)
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $VmDir   = Join-Path $Dir $VmName
     $VhdDir  = Join-Path $VmDir  "Virtual Hard Disks"
     $VhdPath = Join-Path $VhdDir "$VmName.vhd"                    # vhd   (ohne x, da Generation 1)
     New-Item -Path $VhdDir -ItemType Directory | Out-Null
     New-VHD -Path $VhdPath -Differencing -ParentPath $BaseVhd -SizeBytes 0 | Out-Null
     New-VM -Name $VmName -Path $Dir -VHDPath $VhdPath -MemoryStartupBytes $Mem -SwitchName $Switch -Version $Version | Out-Null
     Set-VM -Name $VmName -ProcessorCount $Count
   }
}
  End {}
}
function New-LabVmGen1Copying {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)]                        [string]  $Lab      = $Global:Lab,    
  [Parameter(Mandatory=$false,Position=3)]                        [string]  $Dir      = $Global:LabDir,
  [Parameter(Mandatory=$false,Position=4)]                        [string]  $Switch   = $Global:LabSwitch,
  [Parameter(Mandatory=$false,Position=5)]                        [long]    $Mem      = $Global:LabVmMem,
  [Parameter(Mandatory=$false,Position=6)]                        [long]    $Count    = $Global:LabVmCpuCount,
  [Parameter(Mandatory=$false,Position=7)]                        [string]  $Version  = $Global:LabVmVersion,
  [Parameter(Mandatory=$false,Position=8)]                        [string]  $BaseVhd  = $Global:LabBaseGen1
  )
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $VmDir   = Join-Path $Dir $VmName
     $VhdDir  = Join-Path $VmDir  "Virtual Hard Disks"
     $VhdPath = Join-Path $VhdDir "$VmName.vhd"                    # vhd   (ohne x, da Generation 1)
     New-Item -Path $VhdDir -ItemType Directory | Out-Null
     Copy-Item -Path $BaseVhd -Destination $VhdPath
     New-VM -Name $VmName -Path $Dir -VHDPath $VhdPath -MemoryStartupBytes $Mem -SwitchName $Switch -Version $Version | Out-Null
     Set-VM -Name $VmName -ProcessorCount $Count
   }
}
  End {}
}

function New-LabVm {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)]                        [string]  $Lab      = $Global:Lab,    
  [Parameter(Mandatory=$false,Position=3)]                        [string]  $Dir      = $Global:LabDir,
  [Parameter(Mandatory=$false,Position=4)]                        [string]  $Switch   = $Global:LabSwitch,
  [Parameter(Mandatory=$false,Position=5)]                        [long]    $Mem      = $Global:LabVmMem,
  [Parameter(Mandatory=$false,Position=6)]                        [long]    $Count    = $Global:LabVmCpuCount,
  [Parameter(Mandatory=$false,Position=7)]                        [string]  $Version  = $Global:LabVmVersion
  )
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $VmDir   = Join-Path $Dir $VmName
     $VhdDir  = Join-Path $VmDir  "Virtual Hard Disks"
     $VhdPath = Join-Path $VhdDir "$VmName.vhdx"                   # vhdx   (Generation 2)
     New-Item -Path $VhdDir -ItemType Directory | Out-Null
     New-VHD -Path $VhdPath -Dynamic -SizeBytes 127GB | Out-Null
     New-VM -Name $VmName -Generation 2 -Path $Dir -VHDPath $VhdPath -MemoryStartupBytes $Mem -SwitchName $Switch -Version $Version | Out-Null
     Set-VM -Name $VmName -ProcessorCount $Count
   }
  }
  End {}
}
function New-LabVmDifferencing {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)]                        [string]  $Lab      = $Global:Lab,    
  [Parameter(Mandatory=$false,Position=3)]                        [string]  $Dir      = $Global:LabDir,
  [Parameter(Mandatory=$false,Position=4)]                        [string]  $Switch   = $Global:LabSwitch,
  [Parameter(Mandatory=$false,Position=5)]                        [long]    $Mem      = $Global:LabVmMem,
  [Parameter(Mandatory=$false,Position=6)]                        [long]    $Count    = $Global:LabVmCpuCount,
  [Parameter(Mandatory=$false,Position=7)]                        [string]  $Version  = $Global:LabVmVersion,
  [Parameter(Mandatory=$false,Position=8)]                        [string]  $BaseVhd  = $Global:LabBaseGen2
  )
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $VmDir   = Join-Path $Dir $VmName
     $VhdDir  = Join-Path $VmDir  "Virtual Hard Disks"
     $VhdPath = Join-Path $VhdDir "$VmName.vhdx"
     New-Item -Path $VhdDir -ItemType Directory | Out-Null
     New-VHD -Path $VhdPath -Differencing -ParentPath $BaseVhd -SizeBytes 127GB | Out-Null
     Mount-VHD -Path $VhdPath
     $DriveLetter = Get-DiskImage -ImagePath $VhdPath | Get-Disk | Get-Partition | Get-Volume | 
        Where-Object FileSystemLabel -NE "Recovery" | Select-Object -ExpandProperty DriveLetter
     $AnswerFile = $DriveLetter + ":\Windows\Panther\unattend.xml"
     (Get-Content $AnswerFile).Replace('<ComputerName>MyComputer</ComputerName>','<ComputerName>' + $VmComp + '</ComputerName>') | Set-Content $AnswerFile
     Dismount-VHD -Path $VhdPath
     New-VM -Name $VmName -Generation 2 -Path $Dir -VHDPath $VhdPath -MemoryStartupBytes $Mem -SwitchName $Switch -Version $Version | Out-Null
     Set-VM -Name $VmName -ProcessorCount $Count
   }
}
  End {}
}
function New-LabVmCopying {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)]                        [string]  $Lab     = $Global:Lab,    
  [Parameter(Mandatory=$false,Position=3)]                        [string]  $Dir     = $Global:LabDir,
  [Parameter(Mandatory=$false,Position=4)]                        [string]  $Switch  = $Global:LabSwitch,
  [Parameter(Mandatory=$false,Position=5)]                        [long]    $Mem     = $Global:LabVmMem,
  [Parameter(Mandatory=$false,Position=6)]                        [long]    $Count   = $Global:LabVmCpuCount,
  [Parameter(Mandatory=$false,Position=7)]                        [string]  $Version = $Global:LabVmVersion,
  [Parameter(Mandatory=$false,Position=8)]                        [string]  $BaseVhd = $Global:LabBaseGen2
  )
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $VmDir   = Join-Path $Dir $VmName
     $VhdDir  = Join-Path $VmDir  "Virtual Hard Disks"
     $VhdPath = Join-Path $VhdDir "$VmName.vhdx"
     New-Item -Path $VhdDir -ItemType Directory | Out-Null
     Copy-Item -Path $BaseVhd -Destination $VhdPath
     Mount-VHD -Path $VhdPath
     $DriveLetter = Get-DiskImage -ImagePath $VhdPath | Get-Disk | Get-Partition | Get-Volume | 
        Where-Object FileSystemLabel -NE "Recovery" | Select-Object -ExpandProperty DriveLetter
     $AnswerFile = $DriveLetter + ":\Windows\Panther\unattend.xml"
     (Get-Content $AnswerFile).Replace('<ComputerName>MyComputer</ComputerName>','<ComputerName>' + $VmComp + '</ComputerName>') | Set-Content $AnswerFile
     Dismount-VHD -Path $VhdPath
     New-VM -Name $VmName -Generation 2 -Path $Dir -VHDPath $VhdPath -MemoryStartupBytes $Mem -SwitchName $Switch -Version $Version | Out-Null
     Set-VM -Name $VmName -ProcessorCount $Count
   }
  }
  End {}
}

function Remove-LabVm {
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)]                        [string]  $Lab      = $Global:Lab,    
  [Parameter(Mandatory=$false,Position=3)]                        [string]  $Dir      = $Global:LabDir
  )
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $VmDir  = Join-Path $Dir $VmName 
     Get-VM -Name $VmName | where state -EQ "running" | Stop-VM -Force
     Remove-VM -Name $VmName -Force
     Remove-Item -Path $VmDir -Recurse -Force
   }
}
  End {}
}
function Remove-Lab {
  # All params are mandatory because is's dangerous to remove defaults
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true,Position=1)][string]$Lab,
  [Parameter(Mandatory=$true,Position=2)][string]$Dir,
  [Parameter(Mandatory=$true,Position=3)][string]$Switch
  )

# remove VMs
Get-Lab -Lab $Lab | foreach {
     $VmName = $_.Name
     $VmComputerName = ConvertTo-VmComputerName -VmName $VmName
     Revert-LabVm -VmComputerName $VmComputerName -Lab $Lab
     }

# remove LabDir
if (Test-Path -Path $Dir) { rmdir $Dir -Force }
else {Write-Output $('$LabDir  ' + $Dir + '  does not exist. Nothing to do.')} 

# remove LabSwitch
if (Get-VMSwitch -Name $Switch -ErrorAction SilentlyContinue) { Remove-VMSwitch -Name $Switch -Force }
else {Write-Output $('$LabSwitch  ' + $Switch + '  already exists. Nothing to do.')}

# remove LabRouter
 # todo
}

function Connect-LabVm {
  [CmdletBinding()]Param(
[Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
[Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
)
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     vmconnect.exe localhost $VmName
   }
}
  End {}
}

function Revert-LabVm {
  <#
.SYNOPSIS
	Reverts a virtual machine to the latests snapshot.
.DESCRIPTION
	Reverts a virtual machine to the latests snapshot.
.PARAMETER ComputerName
	The computer name inside the virtual machine.
.PARAMETER Lab
	The name of the lab. A lab is a collection of Virtual machines starting with the same prefix.
.EXAMPLE
	Revert-LabVm -ComputerName LON-DC1 -Lab 21410D
#>
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][string[]]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)][string]$Lab = $Global:Lab
  )
  Begin {}
  Process {
   foreach ($VmComp in $VmComputerName){
     $VmName  = ConvertTo-VmName -VmComputerName $VmComp -Lab $Lab
     $Snapshot = Get-VMSnapshot -VMName $VmName | 
        Sort-Object -Property CreationTime | 
        Select-Object -Last 1
     $SnapshotName = $Snapshot | % Name
     if ($SnapshotName)
        {Write-Output "${VmName}: Reverting to    $SnapshotName"
         Restore-VMSnapshot -VMSnapshot $Snapshot -Confirm:$false}
     else
        {Write-Warning "${VmName}: There is no snapshot."}   
   }
}
  End {}
}
function Revert-Lab {
  [CmdletBinding()]Param(
[Parameter(Mandatory=$false,Position=1)][string]$Lab = $Global:Lab
)
  Get-Lab -Lab $Lab | foreach {
       $VmName = $_.Name
       $VmComputerName = ConvertTo-VmComputerName -VmName $VmName
       Revert-LabVm -VmComputerName $VmComputerName -Lab $Lab
    }
}

function New-LabRouter {
  
  [CmdletBinding()]Param(
  [Parameter(Mandatory=$true, Position=1)][string]$VmComputerName,
  [Parameter(Mandatory=$false,Position=2)][string]$Lab      = $Global:Lab,    
  [Parameter(Mandatory=$false,Position=3)][string]$Dir      = $Global:LabDir,
  [Parameter(Mandatory=$false,Position=4)][string]$Switch   = $Global:LabSwitch,
  [Parameter(Mandatory=$false,Position=5)][string]$Version  = $Global:LabVmVersion,
  [Parameter(Mandatory=$false,Position=6)][string]$BaseVhd  = $Global:LabBaseGen1
  )
  
  [int64]$Mem = 512MB
  [int]$Count = 1
  [string]$Switch_External = "External Network"

  $VmName = ConvertTo-VmName -VmComputerName $VmComputerName

  New-LabVmGen1Copying -VmComputerName $VmComputerName `
                       -Lab $Lab `
                       -Dir $Dir `
                       -Switch $Switch `
                       -Mem  $Mem `
                       -Count $Count `
                       -Version $Version `
                       -BaseVhd $BaseVhd 
  
  Remove-VMNetworkAdapter -VMName $VmName
  Add-VMNetworkAdapter -VMName $VmName -Name "Private"  -SwitchName $Switch
  Add-VMNetworkAdapter -VMName $VmName -Name "External" -SwitchName $Switch_External
  
  Start-LabVm $VmComputerName
  Connect-LabVm $VmComputerName
  
  Write-Host -ForegroundColor Yellow '---------------------------'
  Write-Host -ForegroundColor Yellow '  login:    vyos'
  Write-Host -ForegroundColor Yellow '  Password: Pa55w.rd'
  Write-Host -ForegroundColor Yellow ''
  Write-Host -ForegroundColor Yellow '  vi /config/config.boot'
  Write-Host -ForegroundColor Yellow '  :wq'
  Write-Host -ForegroundColor Yellow ''
  Write-Host -ForegroundColor Yellow '  reboot now'
  Write-Host -ForegroundColor Yellow '---------------------------'
}