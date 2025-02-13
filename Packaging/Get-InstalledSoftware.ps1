Param (
    [parameter(mandatory=$True)]
    [string]$ComputerName,

    [parameter(mandatory=$False)]
    [string]$Software
)

$Keys = @(
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$ScriptBlock = {
    $Products = Get-ItemProperty -Path $Keys -ErrorAction SilentlyContinue

    return $Products
}

if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
    Write-Host -ForegroundColor Red "${ComputerName}: not reachable"
} else {
    try {
        $Products = Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
    } catch {
        Write-Host -ForegroundColor Red "${ComputerName}: unable to establish PSSession"
    }

    if ($Product -ne "") {
        $Products | Where-Object { $_.DisplayName -match $Product }
    } else {
        $Products
    }
}
