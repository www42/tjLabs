$File = "C:\temp\CopyProfile_and_OOBE_and_Computername.xml"

(Get-Content $File).Replace('<ComputerName>MyComputer</ComputerName>','<ComputerName>foo</ComputerName>') | Set-Content $File