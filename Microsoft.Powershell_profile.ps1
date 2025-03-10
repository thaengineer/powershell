########################################

# env
$env:Path = ($env:Path | ForEach-Object { $_ -split ';' } | Sort-Object -Unique) -join ';'
$env:Path = "$env:Path;C:\Users\$($env:USERNAME)\workspace\bin"

# aliases
Set-Alias -Name "vim" -Value "nvim"

# modules
$Modules = Get-ChildItem -Path "C:\Users\$($env:USERNAME)\Documents\WindowsPowerShell\Modules" -Filter "*.psm1"
$Modules | ForEach-Object {
    Import-Module $_.FullName
}

# cwd
if (Test-Path -Path "$($env:USERPROFILE)\workspace") {
    Set-Location -Path "$($env:USERPROFILE)\workspace"
} else {
    Set-Location -Path "$($env:USERPROFILE)"
}

########################################

function Get-CustomFunctions {
    $Functions = (Get-Content -Path $($PROFILE) | Select-String -Pattern '^function\s.*-.*\s\{' | Sort-Object) -replace "(function\s|\s\{)"

    return $Functions | Where-Object { $_ -ne "Get-CustomFunctions" }
}

function Get-Sha256Sum {
    Param (
        [string]$FilePath
    )

    $File = Get-ChildItem -Path $FilePath

    $Sha256Sum = (Get-FileHash -Path $File.FullName -Algorithm SHA256).Hash

    return "$($FilePath.Split("\")[-1])`n$($Sha256Sum)"
}

function TestMachine {
    Param (
        [string]$ComputerName
    )

    Start-Process -FilePath "mstsc.exe" -ArgumentList "/v $($ComputerName)" -NoNewWindow
}

function cdpro {
    Set-Location -Path "$($env:USERPROFILE)\workspace"
}

function rdp {
    Param (
        [string]$ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        Start-Process "mstsc.exe" -ArgumentList "/v $($ComputerName)" -NoNewWindow
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Clear-CcmCache {
    param (
        $ComputerName = $env:COMPUTERNAME
    )

    $ScriptBlock = {
        Remove-Item "C:\WINDOWS\ccmcache\*" -Recurse -Force
        Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent" | Remove-WmiObject
    }

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -AsJob | Out-Null
            Wait-Job *
            Get-Job | Remove-Job
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Get-DiskUsage {
    param (
        $ComputerName = $env:COMPUTERNAME
    )

    $Payload = {
        $Disk  = Get-PSDrive -Name "C";
        $Free  = [Math]::Round($Disk.Free / 1024 / 1024 / 1024, 1)
        $Used  = [Math]::Round($Disk.Used / 1024 / 1024 / 1024, 1)
        $Total = [Math]::Round(($Disk.Free + $Disk.Used) / 1024 / 1024 / 1024, 1)
        $Capacity = [Math]::Round($Used / $Total * 100)

        $Properties = [Ordered]@{
            "ComputerName" = "$($env:COMPUTERNAME)"
            "Filesystem"   = "C"
            "Size"         = "$($Total)G"
            "Used"         = "$($Used)G"
            "Available"    = "$($Free)G"
            "Capacity"     = "$($Capacity)%"
        }

        $Object = New-Object -TypeName PSObject

        $Properties.GetEnumerator() | ForEach-Object {
            $Object | Add-Member -MemberType NoteProperty -Name $_.Key -Value $Properties[$_.Key]
        }

        $Object | Format-Table
    }

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $Payload
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Get-Uptime {
    param (
        $ComputerName = $env:COMPUTERNAME
    )

    $Payload = {
        $UpTime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName).LastBootUpTime
        Write-Host "$((Get-Date -Format "HH:mm")) up $($UpTime.Days) day(s) $($UpTime.Hours):$($UpTime.Minutes)"
    }

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $Payload
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
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
        $ComputerName = $env:COMPUTERNAME
    )

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "winrm qc -quiet" -ComputerName $ComputerName -Namespace root\cimv2 -ErrorAction Stop | Out-Null
            Write-Host -ForegroundColor Cyan "$($ComputerName) : enabled WinRM"
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : failed to enable WinRM"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Get-LoggedOn {
    param (
        $ComputerName = $env:COMPUTERNAME
    )

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            $UserID = ((Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName).UserName -split '\\')[-1]

            if ("" -eq $UserID) {
                Write-Host "nobody"
            } else {
                Get-ADUser -Identity $UserID | Select-Object -Property Name, GivenName, Surname
            }
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Get-OsPatches {
    Param (
        $ComputerName = $env:COMPUTERNAME
    )

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            Get-HotFix -ComputerName $ComputerName | Sort-Object -Property HotFixID
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Get-PendingReboot {
    param (
        $ComputerName = $env:COMPUTERNAME
    )

    $Payload = {
        if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
            Write-Host -ForegroundColor Cyan "[Reboot Pending] Windows Update"
        }

        if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) {
            Write-Host -ForegroundColor Cyan "[Reboot Pending] Component Based Servicing"
        }

        if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending") {
            Write-Host -ForegroundColor Cyan "[Reboot Pending] Windows Server Update Services"
        }

        if (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) {
            Write-Host -ForegroundColor Cyan "[Reboot Pending] File Rename Operations"
        }
    }

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $Payload
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Get-OsVersion {
    param (
        $ComputerName = $env:COMPUTERNAME
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

        $Properties = [Ordered]@{
            'ComputerName'        = "$($env:COMPUTERNAME)"
            'Name'                = "$($OsName)"
            'Version'             = "$($Version).$($UBR)"
        }

        $Properties.GetEnumerator() | ForEach-Object {
            $Object | Add-Member -MemberType NoteProperty -Name $_.Key -Value $Properties[$_.Key]
        }

        $Object | Format-Table
    }

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        try {
            Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock
        } catch {
            Write-Host -ForegroundColor Red "$($ComputerName) : WinRM disabled"
        }
    } else {
        Write-Host -ForegroundColor Red "$($ComputerName) : offline"
    }
}

function Get-TimeStamp {
    Param (
        $Message
    )

    $TimeStamp = Get-Date -Format "ddd dd MMM yyyy HH:mm"

    Write-Host "$TimeStamp $Message"
}

function Get-TlsErrors {
    param (
        [int]$Minutes = 5,
        [string]$ComputerName = $env:COMPUTERNAME
    )

    Get-EventLog -ComputerName $ComputerName -LogName System |
        Where-Object { $_.EventId -eq '36871' -and $_.TimeGenerated -gt (Get-Date).AddMinutes(-$Minutes) } |
            Select-Object -Property TimeGenerated, EntryType, Source, EventID, Message |
                Format-Table -Wrap
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
