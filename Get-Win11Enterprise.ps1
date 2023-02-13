$url = 'https://software-static.download.prss.microsoft.com/dbazure/988969d5-f34g-4e03-ac9d-1f9786c66751/22621.525.220925-0207.ni_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso'
$dest = "C:\Downloads\"


Function Get-DateTime() {
    $dateTime = "[$(Get-Date -Format yyyy-MM-dd)] [$(Get-Date -Format HH:mm:ss)]"
    return $dateTime
}


if (!(Test-Path -Path $dest)) {
    New-Item -ItemType Directory -Path $dest
}

Write-Host -ForegroundColor Green "[+] $(Get-DateTime) [Downloading Microsoft Windows 11 x64 Enterprise]"

Invoke-WebRequest -Uri $url -OutFile "${dest}\WIN11_x64_ENT_en-US.iso"

Write-Host -ForegroundColor Green "[+] $(Get-DateTime) [Done]"
