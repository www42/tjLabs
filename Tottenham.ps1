
# Rename ComputerName

function Rename-LabComputer {
    
[CmdletBinding()]Param (
        [Parameter(Mandatory = $true,  Position = 0)][string]$ComputerName
    )

$VmName = ConvertTo-VmName -ComputerName $ComputerName -Lab $Global:Lab

$SecPw = ConvertTo-SecureString -String $Global:LabPw -AsPlainText -Force
$LocalCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Administrator",$SecPw

Invoke-Command -VMName $VmName -Credential $LocalCred {
    Rename-Computer -NewName $using:ComputerName -Restart -Force
    }
}
function Set-LabComputer {

[CmdletBinding()]Param (
        [Parameter(Mandatory = $true,  Position = 0)][string]$ComputerName,
        [Parameter(Mandatory = $true,  Position = 1)][string]$IpAddress,
        [Parameter(Mandatory = $false, Position = 2)][string]$PrefixLength = $Global:LabIpPrefixLength,
        [Parameter(Mandatory = $false, Position = 3)][string]$DefaultGw    = $Global:LabIpDefaultGw,
        [Parameter(Mandatory = $false, Position = 4)][string]$DnsServer    = $Global:LabIpDnsServer
    )

$VmName = ConvertTo-VmName -ComputerName $ComputerName -Lab $Global:Lab

$SecPw = ConvertTo-SecureString -String $Global:LabPw -AsPlainText -Force
$LocalCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Administrator",$SecPw

$IfAlias   = "Ethernet"

Invoke-Command -VMName $VmName -Credential $LocalCred {
    New-NetIPAddress -InterfaceAlias $Using:IfAlias -IPAddress $Using:IpAddress -PrefixLength $Using:PrefixLength -DefaultGateway $Using:DefaultGw | Out-Null
    }

Invoke-Command -VMName $VmName -Credential $LocalCred {
    Set-DnsClientServerAddress -InterfaceAlias $Using:IfAlias -ServerAddresses $using:DnsServer
    }

}  

Rename-LabComputer -ComputerName DC1
Set-LabComputer -ComputerName DC1 -IpAddress "10.0.0.10" 