$url  = 'https://download.microsoft.com/download/f/5/5/f55e3b9c-781d-493b-932b-16aa1b2f6371/MEM_Configmgr_2203.exe?culture=en-us&country=US'
$dest = "C:\Downloads\"


Function Get-DateTime() {
    $dateTime = "[$(Get-Date -Format yyyy-MM-dd)] [$(Get-Date -Format HH:mm:ss)]"
    return $dateTime
}


if (!(Test-Path -Path $dest)) {
    New-Item -ItemType Directory -Path $dest
}

Write-Host -ForegroundColor Green "[+] $(Get-DateTime) [DOWNLOADING SCCM 2203]"

Invoke-WebRequest -Uri $url -SslProtocol Tls12 -OutFile "${dest}\MEM_Configmgr_2203.exe"

Write-Host -ForegroundColor Green "[+] $(Get-DateTime) [DONE]"
