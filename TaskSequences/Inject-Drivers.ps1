<#
.SYNOPSIS
    Inject Drivers into Boot Image
.DESCRIPTION
    Inject-Drivers.ps1 is a boot image script used to inject drivers by mounting winpe.wim and using dism to inject the drivers.
.NOTES
    If the UNC path does not exist, the timestamp and driver path will be written to the missing-drivers.txt file.
.EXAMPLE
    Inject-Drivers.ps1 -ImagePath <PATH_TO_WIM_FILE> -MountDir <MOUNT_DIRECTORY>
#>


$driverDirs = @(
    "\\server01\driver01",
    "\\server01\driver02",
    "\\server01\driver03"
)
$wimImage    = "C:\Image\winpe.wim"
$mountDir    = "C:\temp\mount"
$logFile     = "C:\injection-log.log"
$missingFile = "C:\missing-drivers-$(Get-Date -Format yyyy-MM-dd_HH-mm-ss).txt"
$imageIndex  = (Get-WindowsImage -ImagePath $wimImage).ImageIndex | Select-Object -First 1


if (!(Test-Path $mountDir)) {
    New-Item -ItemType Directory -Path "C:\temp\mount" -Force
}

Mount-WindowsImage -ImagePath $wimImage -Index $imageIndex -Path $mountDir


foreach ($driverDir in $driverDirs)
{
    if (Test-Path $driverDir | Out-Null) {
        try {
            Add-WindowsDriver -Path $mountDir -Driver $driverDir -Recurse -LogPath $logFile
            Write-Output "[*] success: $driverDir" | Out-File -FilePath $logFile -Append
        } catch {
            Write-Output "[!] error: $_.Exception.HResult $driverDir" | Out-File -FilePath $logFile -Append
        }
    } else {
        Write-Output $driverDir | Out-File -FilePath $missingFile -Append
        Write-Output "[!] error: $driverDir does not exist." | Out-File -FilePath $logFile -Append
    }
}


Dismount-WindowsImage -Path $mountDir -Save
Remove-Item -Path $mountDir -Force -Recurse
