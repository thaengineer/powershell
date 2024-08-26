Param (
    [ValidateSet("Install", "Uninstall", IgnoreCase = $true)]
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action = "Install"
)

$Msu = Get-ChildItem -Filter "*.msu" | Select-Object -First 1

Function Test-Update {
    Param (
        [object]$Msu
    )

    $HotFixID = ($Msu.Name | Select-String -Pattern 'kb([0-9]){6,7}').Matches.Value.ToUpper()

    return $HotFixID -in (Get-HotFix).HotFixID
}

Function Install-Update {
    Param (
        [object]$Msu
    )

    @("SSU*.cab", "Windows*.cab") | Foreach-Object {
        Start-Process -FilePath 'expand.exe' -ArgumentList "`"$($Msu.FullName)`" -F:$($_) `"$($Msu.DirectoryName)\`"" -NoNewWindow -Wait
    }

    Get-ChildItem -Filter "*.cab" | Foreach-Object {
        Add-WindowsPackage -Online -PackagePath "$($_.FullName)" -NoRestart -ErrorAction SilentlyContinue
        Remove-Item -Path "$($_.FullName)" -Force -ErrorAction SilentlyContinue
    }
}

Function Uninstall-Update {
    Param (
        [object]$Msu
    )

    @("Windows*.cab") | Foreach-Object {
        Start-Process -FilePath 'expand.exe' -ArgumentList "`"$($Msu.FullName)`" -F:$($_) `"$($Msu.DirectoryName)\`"" -NoNewWindow -Wait
    }

    Get-ChildItem -Filter "*.cab" | Foreach-Object {
        Remove-WindowsPackage -Online -PackagePath "$($_.FullName)" -NoRestart -ErrorAction SilentlyContinue
        Remove-Item -Path "$($_.FullName)" -Force -ErrorAction SilentlyContinue
    }
}


Switch ($Action) {
    'Install'   { If (-not (Test-Update -Msu $Msu)) { Install-Update -Msu $Msu } }
    'Uninstall' { If (Test-Update -Msu $Msu) { Uninstall-Update -Msu $Msu } }
}
