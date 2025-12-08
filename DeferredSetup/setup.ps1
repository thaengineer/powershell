for ($i = 0; $i -le 100; $i++) {
    Clear-Host
    switch -regex ($i) {
        "^\d{1}$" { Write-Host "[  $($i)%]" }
        "^\d{2}$" { Write-Host "[ $($i)%]" }
        "^\d{3}$" { Write-Host "[$($i)%]" }
    }
    Start-Sleep -Milliseconds 50
}
