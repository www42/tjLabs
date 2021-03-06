﻿$Lab = "Base"
$LabDir = "C:\Labs\Base"
$LabSwitch = "External Network"
$Iso = "C:\iso\14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO"  # Windows Server 2016
#$Iso = "C:\iso\17763.1.180914-1434.rs5_release_SERVER_EVAL_x64FRE_en-us.iso"  # Windows Server 2019

#----------------------------------------------------------------
$ComputerName = "WS2016_DesktopExperience_withUpdates1811_en-US"
#$ComputerName = "WS2019_DesktopExperience_withUpdates1811_en-US"
#----------------------------------------------------------------

New-LabVm -ComputerName $ComputerName -Lab $Lab -Dir $LabDir -Switch $LabSwitch

$VmName = "$Lab-$ComputerName"
Add-VMDvdDrive -VMName $VmName
Set-VMDvdDrive -VMName $VmName -Path $Iso
Set-VMFirmware -VMName $VmName -FirstBootDevice (Get-VMDvdDrive -VMName $VmName)

Connect-LabVm -ComputerName $ComputerName

# Install Windows Server manually

# Server Manager:
#   Local Server
#      IE Enhanced Security Configuration: Off (administrators) Off (Users)
#
#   Do not start Server Manager automatically: Check

# Powershell:
#   Update-Help

# cmd:
#   diskperf -y

# Windows Explorer:
#   Folder Options
#      General
#         Open File Explorer To: This PC
#         Show recently used files in Quick access:     uncheck
#         Show frequently used folders in Quick access: uncheck
#      View
#         Hide extension for known file types: uncheck
#         Expand to open folder:               check
#         Show all folders:                    check
#
#  Copy BackInfo\ to C:\Program Files (x86)\
#  BackInfo.exe  shortcut --> shell:common startup

# ZoomIt.exe  --> C:\Windows\System32
# 

# IE:
#   Add Google
#   Set Google default
#   Remove Bing

# funktioniert nicht # Sounds:
# funktioniert nicht #   No sounds

# funktioniert nicht # Select which icons appear on the taskbar: Volume off

# Settings (Win-I):
#   System
#      Power and sleep
#         When plugged in, turn off after: never
#   Update and Security
#      Windows Update

# CopyProfile_and_OOBE_and_Computername.xml -->  C:\Windows\System32\Sysprep\
#
# <speichern als *ante_sysprep*>

# cmd as Administrator!!
#
# --------------------------------------------------------------------------------------------
# cd c:\windows\System32\Sysprep
# .\sysprep /generalize /oobe /shutdown /unattend:.\CopyProfile_and_OOBE_and_Computername.xml
# --------------------------------------------------------------------------------------------

# Wenn fertig kopiert:
$NewBaseFile = "c:\Base\$VmName.vhdx"
Get-FileHash -Algorithm MD5 -Path $NewBaseFile | % Hash  > "$NewBaseFile.md5"