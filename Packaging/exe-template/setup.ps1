param (
    [ValidateSet("Install", "Uninstall", IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = "Install"
)


function Install-Application {
    $Exe     = Get-ChildItem -Filter "*.exe"
    $ExeArgs = ""

    Start-Process -FilePath $Exe.FullName -ArgumentList $ExeArgs -NoNewWindow -Wait
}

function Uninstall-Application {
    $Exe     = Get-ChildItem -Path "" -Filter "*.exe"
    $ExeArgs = ""

    if (Test-Path -Path $Exe.FullName) {
        Start-Process -FilePath $Exe.FullName -ArgumentList $ExeArgs -NoNewWindow -Wait
    }
}

switch ($Action) {
    "Install"   { Install-Application }
    "Uninstall" { Uninstall-Application }
}
