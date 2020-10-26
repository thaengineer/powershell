param(
    [parameter(mandatory=$True)]
    [string]$ComputerName,

    [parameter(mandatory=$False)]
    [switch]$Enable,

    [parameter(mandatory=$False)]
    [switch]$Disable
)


$wlan_status = Invoke-Command $ComputerName { (Get-NetAdapter -Name "Wi-Fi").Status }


function enable_wlan() {
    try {
        Invoke-Command $ComputerName { Enable-NetAdapter -Name "Wi-Fi" -Confirm:$false }
        Write-Host "Wi-Fi adapter has been enabled on $ComputerName"
    }
    catch {
        Write-Host "The Wi-Fi adapter on $ComputerName is already enabled."
    }
}


function disable_wlan() {
    try {
        Invoke-Command $ComputerName { Disable-NetAdapter -Name "Wi-Fi" -Confirm:$false }
        Write-Host "Wi-Fi adapter has been enabled on $ComputerName"
    }
    catch {
        Write-Host "The Wi-Fi adapter on $ComputerName is already disabled."
    }
}


if($Enable) {
    if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        enable_wlan
    }
    else {
        Write-Host -ForegroundColor red "Unable to connect to $ComputerName."
    }
}
elseif($Disable) {
    if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        disable_wlan
    }
    else {
        Write-Host -ForegroundColor red "Unable to connect to $ComputerName."
    }
}
else {
    Write-Host "Usage: .\Set-WNIC.ps1 -ComputerName <hostname> -[Enable|Disable]"
}
