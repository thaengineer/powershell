Param (
    [parameter(Mandatory = $false, Position = 0)]
    [string]$Software = '',

    [parameter(Mandatory = $false, Position = 1)]
    [string]$ComputerName = $env:COMPUTERNAME
)

$Keys = @(
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$ScriptBlock = {
    $Products = Get-ItemProperty -Path $Keys -ErrorAction SilentlyContinue

    return $Products
}

if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
    Write-Host -ForegroundColor Red "$($ComputerName) not reachable."
    break
}

try {
    $Products = Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ErrorAction Stop
} catch {
    Write-Host -ForegroundColor Red "$($ComputerName) unable to establish PSSession."
    break
}

if ($Software -ne '') {
    $Products | Where-Object { $_.DisplayName -match $Software } | Select-Object -Property DisplayName, DisplayVersion, UninstallString
} else {
    $Products | Select-Object -Property DisplayName, DisplayVersion, UninstallString
}
