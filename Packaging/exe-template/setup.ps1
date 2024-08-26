Param (
    [ValidateSet("Install", "Uninstall", IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = "Install"
)

$Exe = Get-ChildItem -Filter "*.exe" | Select-Object -First 1

Function Install-Application {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Exe
    )

    $InstallArgs = ""

    Start-Process -FilePath $Exe.FullName -ArgumentList "$($InstallArgs)" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

Function Uninstall-Application {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Exe
    )

    $UninstallArgs = ""

    Start-Process -FilePath $Exe.FullName -ArgumentList "$($UninstallArgs)" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

Switch ($Action) {
    'Install'   { Install-Application -Exe $Exe }
    'Uninstall' { Uninstall-Application -Exe $Exe }
}
