Param (
    [ValidateSet("Install", "Uninstall", IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = "Install"
)

$Msi = Get-ChildItem -Filter "*.msi" | Select-Object -First 1

Function Install-Application {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Msi
    )

    $Version = ($Msi.Name | Select-String -Pattern "\d{2}(\.\d){1,2}").Matches.Value
    $LogFile = "C:\Temp\Install-ProductName-$($Version).log"
    $MsiArgs = "/i `"$($Msi.Name)`" /qn /norestart /l*v $($LogFile)"

    Start-Process -FilePath "msiexec.exe" -ArgumentList "$($ArgList)" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

Function Uninstall-Application {
    $Products = [ordered]@{
        "ProductName1-Version1" = "{00000000-0000-0000-0000-000000000000}"
        "ProductName2-Version2" = "{00000000-0000-0000-0000-000000000000}"
    }

    $Products.GetEnumerator() | Foreach-Object {
        $LogFile = "C:\Temp\Uninstall-$().log"
        $MsiArgs = "/x $($_.Value) /qn /norestart /l*v $($LogFile)"

        Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -NoNewWindow -Wait -ErrorAction SilentlyContinue
    }
}

Switch ($Action) {
    'Install'   { Install-Application -Msi $Msi }
    'Uninstall' { Uninstall-Application }
}
