param (
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$ComputerName,

	[Parameter(Mandatory = $false, Position = 0)]
	[int]$Days = 30
)


function Write-Log {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [ValidateSet('Information', 'Warning', 'Error', IgnoreCase = $true)]
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Type = 'Information'
    )

    $TimeStamp = Get-Date -Format 'yyyy/MM/dd HH:mm:ss'

    Switch ($Type) {
        'Information' { Write-Host "$($TimeStamp) " -NoNewline; Write-Host -ForegroundColor Green "[+] " -NoNewline; Write-Host $Message }
        'Warning'     { Write-Host "$($TimeStamp) " -NoNewline; Write-Host -ForegroundColor Yellow "[*] " -NoNewline; Write-Host $Message }
        'Error'       { Write-Host "$($TimeStamp) " -NoNewline; Write-Host -ForegroundColor Red "[!] " -NoNewline; Write-Host $Message }
    }
}


if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
    Write-Log -Message "Unable to connect to $($ComputerName)" -Type Error
    break
}

try {
    $Accounts    = Get-CimInstance -ClassName Win32_UserProfile -ComputerName $ComputerName -ErrorAction Stop
    $OldAccounts = $Accounts | Where-Object { -not $_.Special -and $_LastUseTime -le (Get-Date).AddDays(-$Days) }
} catch {
    Write-Log -Message "Failed to query user profiles older than $($Days) days on $($ComputerName)." -Type Error
}

$OldAccounts | ForEach-Object {
    Write-Log -Message "Removing user profile $($_.LocalPath.Split('\')[-1])." -Type Warning
    Remove-CimInstance -ComputerName $ComputerName -InputObject $_
}

Write-Log -Message "Done." -Type Information
