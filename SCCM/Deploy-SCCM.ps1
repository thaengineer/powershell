$StateFile    = "C:\Temp\state.txt"
$DomainName   = "homelabcoderz.com"
$ADDSHostName = "DC01"
$SCCMHostName = "CM01"
# $SiteCode     = "S01"
$NIC          = (Get-NetAdapter).Name
$IPAddress    = "10.0.0.3"
$PrefixLen    = 24
$GateWay      = "10.0.0.1"
$DNSServers   = ("10.0.0.2", "1.1.1.1")
$DomainAdmin  = "$DomainName\Administrator"
$Pass         = ConvertTo-SecureString -String "Password?123" -AsPlainText -Force
$Credential   = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainAdmin, $Pass


if(! (Test-Path -Path "C:\Temp"))
{
    New-Item -Path "C:\" -Name "Temp" -ItemType Directory | Out-Null
}


if(! (Test-Path -Path "C:\Temp\state.txt"))
{
    New-Item -Path "C:\Temp" -Name "state.txt" -ItemType File | Out-Null
    "0" | Out-File -FilePath $StateFile
}


if((Get-Content $StateFile) -eq 0)
{
    Write-Host "joining: [$(Get-Date -Format "HH:mm:ss")] [$SCCMHostName -> $DomainName]"

    New-NetIPAddress -IPAddress $IPAddress -InterfaceAlias $NIC -DefaultGateway $GateWay -AddressFamily "IPv4" -PrefixLength $PrefixLen
    Set-DnsClientServerAddress -InterfaceAlias $NIC -ServerAddresses $DNSServers

    Add-Computer -Credential $Credential -DomainName $DomainName -Server $ADDSHostName -NewName $SCCMHostName

    "1" | Out-File -FilePath $StateFile

    Restart-Computer
}


if((Get-Content $StateFile) -eq 1)
{
    Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [.NET Features]"
    Install-WindowsFeature -Name "NET-Framework-Features" -IncludeAllSubFeature # needs restart after
    Install-WindowsFeature -Name "NET-Framework-45-Features" -IncludeAllSubFeature # needs restart after

    Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [BITS Features]"
    Install-WindowsFeature -Name "BITS" -IncludeAllSubFeature
    Install-WindowsFeature -Name "RDC"

    Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [IIS Web Server Role]"
    Install-WindowsFeature -Name "Web-Server" -IncludeManagementTools -IncludeAllSubFeature

    "2" | Out-File -FilePath $StateFile

    exit(0)
}


if((Get-Content $StateFile) -eq 2)
{
    Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [Assessment and Deployment Kit]"

    Start-Process -FilePath "C:\Media\ADK\adksetup.exe" -ArgumentList '/ceip off /norestart /features OptionId.DeploymentTools OptionId.UserStateMigrationTool /q' -Wait -WindowStyle Hidden
    Start-Process -FilePath "C:\Media\ADKPE\adkwinpesetup.exe" -ArgumentList '/ceip off /norestart /features OptionId.WindowsPreinstallationEnvironment /q' -Wait -WindowStyle Hidden

    "3" | Out-File -FilePath $StateFile

    exit(0)
}


if((Get-Content $StateFile) -eq 3)
{
    Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [Microsoft SQL Server]"

    Start-Process -FilePath "C:\Media\SQL\setup.exe" -ArgumentList "/CONFIGURATIONFILE=C:\Media\SQL\ConfigurationFile.ini /IACCEPTSQLSERVERLICENSETERMS" -Wait #-WindowStyle Hidden
    Start-Process -FilePath "C:\Media\SQL\SQLServerReportingServices.exe" -ArgumentList "/passive /norestart /IAcceptLicenseTerms /Edition=Eval" -Wait -WindowStyle Hidden
    Start-Process -FilePath "C:\Media\SQL\SSMS-Setup-ENU.exe" -ArgumentList "/install /passive /norestart" -Wait -WindowStyle Hidden

    "4" | Out-File -FilePath $StateFile

    exit(0)
}


if((Get-Content $StateFile) -eq 4)
{
    Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [WSUS]"
    Install-WindowsFeature -Name "WAS" -IncludeAllSubFeature
    Install-WindowsFeature -Name "Windows-Internal-Database" -IncludeAllSubFeature
    Install-WindowsFeature -Name "UpdateServices-RSAT" -IncludeManagementTools -IncludeAllSubFeature
    Install-WindowsFeature -Name "UpdateServices-Services"
    Install-WindowsFeature -Name "UpdateServices-DB"

    & "C:\Program Files\Update Services\Tools\WsusUtil.exe" postinstall CONTENT_DIR=C:\Sources\Updates SQL_INSTANCE_NAME=$SCCMHostName.$DomainName

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\404" -Name "ConfigurationState" -Value "2"

    "5" | Out-File -FilePath $StateFile

    exit(0)
}


if((Get-Content $StateFile) -eq 5)
{
    Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [System Center Configuration Manager]"

    Start-Process -FilePath "C:\Media\SCCM\SMSSETUP\BIN\X64\setup.exe" -ArgumentList "/script C:\Media\SCCM\ConfigMgr.ini" -Wait -WindowStyle Hidden

    "6" | Out-File -FilePath $StateFile
}


if((Get-Content $StateFile) -eq 6)
{
    Remove-Item -Path $StateFile | Out-Null

    Write-Host "done: [$(Get-Date -Format "HH:mm:ss")]"
}


#$PayLoad = {
#    Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True -Profile Private
#}
#Invoke-Command -ComputerName $ADDSHostName -ScriptBlock $PayLoad

#Write-Host "installing: [$(Get-Date -Format "HH:mm:ss")] [MDT]"
#Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i C:\Media\MDT\MicrosoftDeploymentToolkit_x64.msi /q /n /norestart" -Wait -WindowStyle Hidden
