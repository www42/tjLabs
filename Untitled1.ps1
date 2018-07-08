
function ConvertTo-ComputerName {
 <#
.Synopsis
   Converts VmName to ComuterName by trimming off the LAB string
.DESCRIPTION
   Within LAB environment this function converts a VmName into the corresponding ComputerName by trimming off the LAB string.
   E. g. "20740B-DC1" becomes "DC1" within 20740B Lab.
.EXAMPLE
   ConvertTo-ComputerName  20740B-DC1  20740B
#>
 Param (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$VmName,

        [Parameter(Mandatory=$true,Position=1)]
        [string]$Lab
    )
 $ComputerName = $VmName.TrimStart($Lab)
 Write-Output $ComputerName
}