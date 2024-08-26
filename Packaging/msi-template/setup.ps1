Param (
    [ValidateSet("Install", "Uninstall", IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = "Install"
)

$Msi = Get-ChildItem -Filter "*.msi" | Select-Object -First 1

Function Install-Application {
    Param (
        [object]$Msi
    )

    $ArgList = "/i `"$($Msi.Name)`" /qn /norestart"

    Start-Process -FilePath "msiexec.exe" -ArgumentList "$($ArgList)" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

Function Uninstall-Application {
    Param (
        [object]$Msi
    )

    $ArgList = "/x `"$($Msi.Name)`" /qn /norestart"

    Start-Process -FilePath "msiexec.exe" -ArgumentList "$($ArgList)" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

Switch ($Action) {
    'Install'   { Install-Application -Msi $Msi }
    'Uninstall' { Uninstall-Application -Msi $Msi }
}
