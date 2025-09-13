param (
    [ValidateSet('Install', 'Uninstall', IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = 'Install'
)

if (-not (Test-Path -Path 'C:\Temp')) {
    New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null
}


function Install-Application {
    $Msi     = Get-ChildItem -Filter '*.msi'
    $Version = ($Msi.Name | Select-String -Pattern "(\d+\.){1,2}\d+").Matches.Value
    $LogFile = "C:\Temp\Install-ProductName-$($Version).log"
    $MsiArgs = "/i `"$($Msi.Name)`" /qn /norestart /l*v `"$($LogFile)`""

    Start-Process -FilePath "msiexec.exe" -ArgumentList "$($ArgList)" -NoNewWindow -Wait
}


function Uninstall-Application {
    $Products = [ordered]@{
        "ProductName-Version" = "{00000000-0000-0000-0000-000000000000}"
    }

    $Products.GetEnumerator() | Foreach-Object {
        $Version = ($_.Key | Select-String -Pattern "(\d+\.){1,2}\d+").Matches.Value
        $LogFile = "C:\Temp\Uninstall-ProductName-$($Version).log"
        $MsiArgs = "/x $($_.Value) /qn /norestart /l*v $($LogFile)"

        Start-Process -FilePath 'msiexec.exe' -ArgumentList $MsiArgs -NoNewWindow -Wait -ErrorAction SilentlyContinue
    }
}


Switch ($Action) {
    'Install'   { Install-Application }
    'Uninstall' { Uninstall-Application }
}
