param (
    [ValidateSet('Install', 'Uninstall', IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = 'Install'
)


function Test-Update {
    $Msu      = Get-ChildItem -Filter "*.msu"
    $HotFixID = ($Msu.Name | Select-String -Pattern 'kb\d+').Matches.Value.ToUpper()

    return $HotFixID -in (Get-HotFix).HotFixID
}


function Install-Update {
    $Msu = Get-ChildItem -Filter "*.msu"

    @("SSU*.cab", "Windows*.cab") | Foreach-Object {
        Start-Process -FilePath 'expand.exe' -ArgumentList "`"$($Msu.FullName)`" -F:$($_) `"$($Msu.DirectoryName)\`"" -NoNewWindow -Wait
    }

    Get-ChildItem -Filter "*.cab" | Foreach-Object {
        Add-WindowsPackage -Online -PackagePath "$($_.FullName)" -NoRestart -ErrorAction SilentlyContinue
        Remove-Item -Path "$($_.FullName)" -Force
    }
}


function Uninstall-Update {
    $Msu = Get-ChildItem -Filter "*.msu"

    @("Windows*.cab") | Foreach-Object {
        Start-Process -FilePath 'expand.exe' -ArgumentList "`"$($Msu.FullName)`" -F:$($_) `"$($Msu.DirectoryName)\`"" -NoNewWindow -Wait
    }

    Get-ChildItem -Filter "*.cab" | Foreach-Object {
        Remove-WindowsPackage -Online -PackagePath "$($_.FullName)" -NoRestart -ErrorAction SilentlyContinue
        Remove-Item -Path "$($_.FullName)" -Force -ErrorAction SilentlyContinue
    }
}


switch ($Action) {
    'Install'   { if (-not (Test-Update -Msu $Msu)) { Install-Update } }
    'Uninstall' { if (Test-Update -Msu $Msu) { Uninstall-Update } }
}
