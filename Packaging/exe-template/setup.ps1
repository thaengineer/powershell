param (
    [ValidateSet('Install', 'Uninstall', IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = 'Install'
)


function Install-Application {
    $Exe     = Get-ChildItem -Filter '*.exe' | Select-Object -First 1
    $ExeArgs = ""

    Start-Process -FilePath $Exe.FullName -ArgumentList $ExeArgs -NoNewWindow -Wait
}

function Uninstall-Application {
    $Exe     = Get-ChildItem -Path '' -Filter '*.exe'
    $ExeArgs = ""

    if (-not (Test-Path -Path $Exe.FullName)) {
        break
    }

    Start-Process -FilePath $Exe.FullName -ArgumentList $ExeArgs -NoNewWindow -Wait
}

switch ($Action) {
    'Install'   { Install-Application }
    'Uninstall' { Uninstall-Application }
}
