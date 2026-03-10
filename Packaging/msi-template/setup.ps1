param (
    [ValidateSet("Install", "Uninstall", IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = "Install"
)


function Get-MsiProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf -Include *.msi})]
        [string]$MsiPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ProductName', 'ProductVersion', 'ProductCode')]
        [string]$Property
    )

    $ErrorActionPreference = 'Stop'

    $installer = New-Object -ComObject WindowsInstaller.Installer
    $database  = $installer.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $installer, @($MsiPath, 0))
    $query     = "SELECT Value FROM Property WHERE Property='$Property'"

    $view = $database.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $database, @($query))
    $view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null) | Out-Null

    $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
    $value = if ($record) { $record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, 1) } else { $null }

    # clean up com objects to avoid file locks
    if ($view)   { [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($view)   }
    if ($database) { [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) }
    if ($installer) { [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer) }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    return $value
}


function Install-Application {
    $Msi            = Get-ChildItem -Filter "*.msi"
    $ProductName    = Get-MsiProperty -MsiPath $Msi.FullName -Property "ProductName"
    $ProductVersion = Get-MsiProperty -MsiPath $Msi.FullName -Property "ProductVersion"
    $LogFile        = "$($env:SystemDrive)\Temp\Install-$($ProductName)-$($ProductVersion).log"
    $MsiArgs        = "/i `"$($Msi.Name)`" /qn /norestart /l*v `"$($LogFile)`""

    Uninstall-Application
    Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -NoNewWindow -Wait
}


function Uninstall-Application {
    $Msi            = Get-ChildItem -Filter "*.msi"
    $ProductName    = Get-MsiProperty -MsiPath $Msi.FullName -Property "ProductName"
    $ProductVersion = Get-MsiProperty -MsiPath $Msi.FullName -Property "ProductVersion"
    $ProductCode    = Get-MsiProperty -MsiPath $Msi.FullName -Property "ProductCode"

    if ($null -ne $ProductCode) {
        $LogFile = "$($env:SystemDrive)\Temp\Uninstall-$($ProductName)-$($ProductVersion).log"
        $MsiArgs = "/x $($ProductCode) /qn /norestart /l*v `"$($LogFile)`""

        Start-Process -FilePath "msiexec.exe" -ArgumentList $MsiArgs -NoNewWindow -Wait -ErrorAction SilentlyContinue
    }
}


switch ($Action) {
    "Install"   { Install-Application }
    "Uninstall" { Uninstall-Application }
}
