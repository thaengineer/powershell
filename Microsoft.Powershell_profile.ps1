# tls 1.2
# if ([bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#     [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# }

# env
$EnvMachine = ([System.Environment]::GetEnvironmentVariable('Path', 'Machine').Split(';') | Sort-Object -Unique | Where-Object { $_ -ne '' }) -join ';'
$EnvUser    = ([System.Environment]::GetEnvironmentVariable('Path', 'User').Split(';') | Sort-Object -Unique | Where-Object { $_ -ne '' }) -join ';'

[System.Environment]::SetEnvironmentVariable('Path', $EnvMachine, 'Machine')
[System.Environment]::SetEnvironmentVariable('Path', $EnvUser, 'User')

if (Test-Path -Path "$($env:USERPROFILE)\bin") { $env:Path = "$env:Path;$($env:USERPROFILE)\bin" }
if (Test-Path -Path 'C:\Program Files\Neovim\bin') { $env:Path = "$env:Path;C:\Program Files\Neovim\bin" }


# modules
$PSModulePath = $env:PSModulePath.Split(';') | Where-Object { $_ -match $env:USERNAME}
Get-ChildItem -Path $PSModulePath -Filter "*.psm1" | ForEach-Object { Import-Module $_.FullName }


# working directory
Set-Location -Path $env:USERPROFILE


# aliases
if (Test-Path -Path 'C:\Program Files\Neovim\bin\nvim.exe') { Set-Alias -Name "vim" -Value "nvim" }


# functions
function Get-CustomFunctions {
    $Functions = (Get-Content -Path $PROFILE | Select-String -Pattern '^function\s\w+-\w+' | Sort-Object -Unique) -replace 'function\s', ''

    return $Functions | Where-Object { $_ -ne 'Get-CustomFunctions' }
}


function cdpro {
    Set-Location -Path $env:USERPROFILE
}


function Get-Sha256Sum {
    param (
        [string]$FilePath
    )

    try {
        $File      = Get-ChildItem -Path $FilePath -ErrorAction Stop
        $Sha256Sum = (Get-FileHash -Path $File.FullName -Algorithm SHA256).Hash
    } catch {
        Write-Host -ForegroundColor Red "Failed to get sha256 hash"
        break
    }

    return "$($File.Name)`n$($Sha256Sum)"
}


function Get-TimeStamp {
    Param (
        $Message
    )

    $TimeStamp = Get-Date -Format "ddd MMM dd HH:mm"

    Write-Host "$TimeStamp $Message"
}


function Clear-CcmCache {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $ScriptBlock = {
        Remove-Item "C:\WINDOWS\ccmcache\*" -Recurse -Force
        Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent" | Remove-WmiObject | Out-Null
    }

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) WinRM disabled"
    }
}


function Get-DiskUsage {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $ScriptBlock = {
        $Disk                  = Get-PSDrive -Name $($env:SystemDrive.Replace(':', ''))
        $Free                  = [Math]::Round($Disk.Free / 1024 / 1024 / 1024, 1)
        $Used                  = [Math]::Round($Disk.Used / 1024 / 1024 / 1024, 1)
        $Total                 = [Math]::Round(($Disk.Free + $Disk.Used) / 1024 / 1024 / 1024, 1)
        $Capacity              = [Math]::Round($Used / $Total * 100)
        $Table                 = [ordered]@{}
        $Table['ComputerName'] = "$($env:COMPUTERNAME)"
        $Table['Filesystem']   = "$($env:SystemDrive.Replace(':', ''))"
        $Table['Size']         = "$($Total)G"
        $Table['Used']         = "$($Used)G"
        $Table['Available']    = "$($Free)G"
        $Table['Capacity']     = "$($Capacity)%"
        $Properties            = [PSCustomObject]$Table

        return $Properties
    }

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) WinRM disabled"
    }
}


function Get-Uptime {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $ScriptBlock = {
        $UpTime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName).LastBootUpTime
        Write-Host "$((Get-Date -Format "HH:mm"))  up $($UpTime.Days) day(s) $((Get-Date -Hour $UpTime.Hours).ToString("HH")):$((Get-Date -Minute $UpTime.Minutes).ToString("mm"))"
    }

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) WinRM disabled"
    }
}


function Transfer-File {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FilePath,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Destination
    )

    function WriteProgress {
        param (
            [Parameter(Mandatory=$true, Position=0)]
            [string]$FilePath,

            [Parameter(Mandatory=$true, Position=0)]
            [string]$Progress
        )

        Clear-Host
        Write-Host "Copying $($FilePath) ($($Progress)%)"
        Start-Sleep -Seconds 1
    }

    if (-not (Test-Path -Path $Destination)) {
        Write-Host "$($Destination) not found"
    } else {
        $Job = Start-BitsTransfer -Source $FilePath -Destination $Destination -DisplayName "file-transfer" -Priority High -Asynchronous

        while ($Job.BytesTransferred -lt $Job.BytesTotal) {
            $Total       = $Job.BytesTotal
            $Transferred = $Job.BytesTransferred

            if ($Transferred -gt 0) {
                $Progress = [Math]::Round($Transferred / $Total * 100, 2)
            } else {
                $Progress = 0
            }

            WriteProgress -FilePath $FilePath -Progress $Progress
        }

        if ($Job.BytesTransferred -eq $Job.BytesTotal) {
            $Progress = 100

            WriteProgress -FilePath $FilePath -Progress $Progress
        }

        Complete-BitsTransfer -BitsJob $Job
    }
}


function Enable-WinRM {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "winrm qc -quiet" -ComputerName $ComputerName -Namespace root\cimv2 -ErrorAction Stop | Out-Null
        Write-Host -ForegroundColor Yellow "$($ComputerName) enabled WinRM"
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) failed to enable WinRM"
    }
}


function Get-LoggedOn {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        $CimInst  = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction Stop
        $UserName = $CimInst.UserName.Split('\')[-1]

        if ($UserName -eq '' -or $UserName -eq $null) {
            Write-Host -ForegroundColor Yellow "nobody"
        } else {
            Write-Host -ForegroundColor Yellow "$($UserName)"
        }
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) WinRM disabled"
    }
}


function Get-OsPatches {
    Param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        $HotFixes = Get-HotFix -ComputerName $ComputerName -ErrorAction Stop
        $HotFixes | Sort-Object -Property HotFixID
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
    }
}


function Get-PendingReboot {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $ScriptBlock = {
        $Table = [ordered]@{
            '[Reboot Pending] Windows Update'                 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
            '[Reboot Pending] Component Based Servicing'      = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
            '[Reboot Pending] File Rename Operations'         = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager:PendingFileRenameOperations'
        }

        $Table.GetEnumerator() | ForEach-Object {
            $Message = $_.Key

            if ($_.Value -match ':Pending') {
                $Key   = $_.Value.Split(':')[0,1] -join ':'
                $Value = $_.Value.Split(':')[-1]

                if (Get-ItemProperty -Path $Key -Name $Value -ErrorAction SilentlyContinue) {
                    Write-Host -ForegroundColor Yellow $_.Key
                }
            } else {
                if (Test-Path -Path $_.Value) {
                    Write-Host -ForegroundColor Yellow $_.Key
                }
            }
        }
    }

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) WinRM disabled"
    }
}


function Get-OsVersion {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $ScriptBlock = {
        $OsVersion = [System.Environment]::OSVersion.Version
        $Version   = ($OsVersion.Major, $OsVersion.Minor, $OsVersion.Build) -join '.'
        $Object    = New-Object -TypeName PSObject
        $WinNT     = ($OsVersion -split '\.' | Select-Object -First 2) -join '.'
        $UBR       = (Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\' -Name 'UBR').UBR

        switch -Regex ($OsVersion) {
            '10.0.26100' { $OsName = "Windows 11 24H2" }
            '10.0.22631' { $OsName = "Windows 11 23H2" }
            '10.0.22621' { $OsName = "Windows 11 22H2" }
            '10.0.22000' { $OsName = "Windows 11 21H2" }
            '10.0.19045' { $OsName = "Windows 10 22H2" }
            '10.0.19044' { $OsName = "Windows 10 21H2" }
            '10.0.19043' { $OsName = "Windows 10 21H1" }
            '10.0.19042' { $OsName = "Windows 10 20H2" }
            '10.0.19041' { $OsName = "Windows 10 2004" }
            '10.0.18363' { $OsName = "Windows 10 1909" }
            '10.0.18362' { $OsName = "Windows 10 1903" }
            '10.0.17763' { $OsName = "Windows 10 1809" }
            '10.0.17134' { $OsName = "Windows 10 1803" }
            '10.0.16299' { $OsName = "Windows 10 1709" }
            '10.0.15063' { $OsName = "Windows 10 1703" }
            '10.0.14393' { $OsName = "Windows 10 1607" }
            '10.0.10586' { $OsName = "Windows 10 1511" }
            default      { $OsName = "Windows NT $($WinNT)" }
        }

        $Table                 = [ordered]@{}
        $Table['ComputerName'] = "$($env:COMPUTERNAME)"
        $Table['Name']         = "$($OsName)"
        $Table['Version']      = "$($Version).$($UBR)"
        $Properties            = [PSCustomObject]$Table

        return $Properties
    }

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host -ForegroundColor Red "$($ComputerName) is not reachable"
        break
    }

    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock
    } catch {
        Write-Host -ForegroundColor Red "$($ComputerName) WinRM disabled"
    }
}


function Get-InstalledSoftware {
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$false, Position=1)]
        [string]$Software = ""
    )

    $ScriptBlock = {
        param (
            [Parameter(Position=0)]
            [string]$Software
        )

        $Keys = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
        Get-ChildItem -Path "HKU:\S-1-5-21-*" | Where-Object { $_.Name -notmatch "Classes" } | ForEach-Object {
            $Keys += "$($_.PSPath)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
            $Keys += "$($_.PSPath)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        }

        $Products = Get-ItemProperty -Path $Keys -ErrorAction SilentlyContinue | Where-Object { $null -ne $_.DisplayName -and $_.DisplayName -match "$($Software)" }

        Remove-PSDrive -Name HKU

        return $Products
    }

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            $Result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $Software
            $Result | Select-Object @{ Name = "ComputerName"; Expression = { $_.PSComputerName} }, DisplayName, DisplayVersion, @{ Name = "RegHive"; Expression = { $_.PSPath -replace "^.*HKEY_LOCAL_MACHINE.*$", "HKLM" -replace "^.*HKEY_USERS.*$", "HKU" } }, UninstallString |
                Sort-Object -Property DisplayName | Format-Table -AutoSize
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function New-IntunePackage {
    $Exe     = "$($env:USERPROFILE)\workspace\bin\IntuneWinAppUtil.exe"
    $ExeArgs = "-c .\Package -s .\Package\setup.ps1 -o .\"

    if (Test-Path -Path "Package") {
        $PackageName = "$((Get-Location | Get-Item).Name).intunewin"
        Start-Process -FilePath $Exe -ArgumentList $ExeArgs -NoNewWindow -Wait

        if (Test-Path -Path "setup.intunewin") {
            Rename-Item -Path "setup.intunewin" -NewName $PackageName -Force
            Write-Host -ForegroundColor Yellow "Intune package created at:`n$((Get-Location).Path)\$($PackageName)"
        }
    } else {
        Write-Host -ForegroundColor Yellow "The `"Package`" directory does not exist."
    }
}

function PsCtrl {
    $ts = (New-TimeSpan -Start (Get-Date).DateTime -End (Get-Date -Hour 16 -Minute 30 -Second 00).DateTime)
    $h  = $ts.Hours
    $m  = $ts.Minutes


    Add-Type -AssemblyName System.Windows.Forms
    $s = [System.Windows.Forms.SendKeys]::SendWait

    if (0 -ne $h -and 0 -eq $m) {
        $t = $h * 60
    } elseif (0 -eq $h -and 0 -ne $m) {
        $t = $m
    } elseif (0 -ne $h -and 0 -ne $m) {
        $t = ($h * 60) + $m
    } else {
        Write-Host "usage: .\PS.ps1 [-h <1-9>] [-m <1-540>]"
    }

    for ($i = 0; $i -lt $t; $i++) {
        $timestamp = Get-Date -Format "[yyyy-MM-dd HH:mm:ss]"
        $count     = $i + 1
        Clear-Host
        Write-Host "$($timestamp) $($count)/$($t)"
        Start-Sleep -Seconds 60
        $s.Invoke("^")
    }
}
