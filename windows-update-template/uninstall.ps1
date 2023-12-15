# uninstall
Get-ChildItem -Filter '*.msu' | ForEach-Object {
    $Update = $_

    @('Windows*.cab') | ForEach-Object {
        Start-Process -FilePath 'expand.exe' -ArgumentList "$($Update.FullName) -F:$($_) .\" -NoNewWindow -Wait
    }
}

Get-ChildItem -Filter '*.cab' | ForEach-Object {
    Remove-WindowsPackage -Online -PackagePath "$($_.FullName)" -NoRestart -ErrorAction -SilentlyContinue
    Remove-Item -Path "$($_.FullName)" -Force -ErrorAction SilentlyContinue
}
