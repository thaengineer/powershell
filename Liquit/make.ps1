Import-Module -Name ps2exe

Invoke-ps2exe -inputFile '.\LiquitCollectionMemberMgmt.ps1' -outputFile '.\LiquitCollectionMemberMgmt.exe' -x64 -noConsole -title 'Liquit Collection Member Mgmt' -company 'None' -product 'Liquit Collection Member Mgmt' -copyright 'MIT License' -version '1.0' -noConfigFile -noVisualStyles
