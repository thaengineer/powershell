Function Get-DateTime() {
    $dateTime = "[$(Get-Date -Format yyyy-MM-dd)] [$(Get-Date -Format HH:mm:ss)]"
    return $dateTime
}

Write-Host -ForegroundColor Green "[+] $(Get-DateTime) [Disabling Power Management Options]"

powercfg /create Custom
powercfg /Change Custom /monitor-timeout-ac 0
powercfg /Change Custom /monitor-timeout-dc 0
powercfg /Change Custom /disk-timeout-ac 0
powercfg /Change Custom /disk-timeout-dc 0
powercfg /Change Custom /standby-timeout-ac 0
powercfg /Change Custom /standby-timeout-dc 0
powercfg /Change Custom /hibernate-timeout-ac 0
powercfg /Change Custom /hibernate-timeout-dc 0
powercfg /Change Custom /processor-throttle-ac none
powercfg /Change Custom /processor-throttle-dc none
powercfg /setactive Custom
powercfg -h off

Write-Host -ForegroundColor Green "[+] $(Get-DateTime) [Done]"
