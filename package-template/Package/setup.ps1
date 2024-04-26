####################################
# Author:        ????????          #
# Last Modified: 2024-04-26        #
# Application:   ????????          #
# Version:       ????????          #
####################################

Param (
    [ValidateSet('Install', 'Uninstall', IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = 'Install'
)


Function Initialize-LogDir {
    Param (
        [string]$LogFile
    )

    if (-not (Test-Path -Path "$($LogFile)")) {
        New-Item -ItemType Directory -Path "$($LogFile)" -Force | Out-Null
    }
}


Function Write-Log {
    Param (
        [string]$LogFile,
        [string]$Message
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content -Path "$($LogFile)" -Value "$($TimeStamp) $($Message)"
}


Function Install-Application {
    $LogFile = "C:\Temp\install.log"

    Get-ChildItem -Filter '*.msi' | Foreach-Object {
        try {
            Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $($_.Name) /qb /norestart /l*v $($LogFile)" -NoNewWindow -Wait -ErrorAction Stop
        }
        catch {
            Write-Log -LogFile "$($LogFile)" -Message "Install successful."
        }
    }
}


Function Uninstall-Application {
    $LogFile = "C:\Temp\uninstall.log"

    Get-ChildItem -Filter '*.msi' | Foreach-Object {
        try {
            Start-Process -FilePath 'msiexec.exe' -ArgumentList "/x $($_.Name) /qb /norestart /l*v $($LogFile)" -NoNewWindow -Wait -ErrorAction Stop
        }
        catch {
            Write-Log -LogFile "$($LogFile)" -Message "Uninstall failed."
        }
    }
}


Initialize-LogDir -LogFile "C:\Temp"

Switch ($Action) {
    'Install'   { Install-Update }
    'Uninstall' { Uninstall-Update }
}
