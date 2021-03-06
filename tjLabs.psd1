@{
RootModule    = './tjLabs.psm1'
ModuleVersion = '0.4.6'
Author        = 'Thomas Jaekel'
Copyright     = '(c) 2016 Thomas Jaekel. All rights reserved.'
Description   = 'Create and manage Lab VMs.'
GUID          = '1c5e644c-3bdc-4aee-8624-6e02b840a7d9'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('ConvertTo-ComputerName',
                      'ConvertTo-VmName',
                      'Get-LabVm',
                      'Get-Lab',
                      'Show-LabVm',
                      'Show-Lab',
                      'Start-LabVm',
                      'Stop-LabVm',
                      'Stop-Lab',
                      'Checkpoint-LabVm',
                      'Checkpoint-Lab',
                      'New-Lab',
                      'New-LabVm',
                      'New-LabVmDifferencing',
                      'New-LabVmCopying',
                      'New-LabVmGen1',
                      'New-LabVmGen1Differencing',
                      'New-LabVmGen1Copying',
                      'Remove-Lab',
                      'Remove-LabVm',
                      'Connect-LabVm',
                      'Revert-LabVm',
                      'Revert-Lab',
                      'New-LabRouter')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
#VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @('shl')
}