Get-ChildItem -Filter '*.msu' | ForEach-Object {
    $Update = $_

    @('SSU*.cab', 'Windows*.cab') | ForEach-Object {
        Start-Process -FilePath 'expand.exe' -ArgumentList "$($Update.FullName) -F:$($_) .\" -NoNewWindow -Wait
    }
}

Get-ChildItem -Filter '*.cab' | ForEach-Object {
    Add-WindowsPackage -Online -PackagePath "$($_.FullName)" -NoRestart -ErrorAction -SilentlyContinue
    Remove-Item -Path "$($_.FullName)" -Force -ErrorAction SilentlyContinue
}
