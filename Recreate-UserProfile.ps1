param (
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$ComputerName,
	
	[Parameter(mandatory=$true, Position = 1)]
	[string]$UserName
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
    $Account     = Get-CimInstance -ClassName Win32_UserProfile -Filter "LocalPath like '%$($UserName)'" -ComputerName $env:COMPUTERNAME -ErrorAction Stop
    $AccountSid  = $Account.SID
    $DriveLetter = $Account.LocalPath.Split('\')[0].Replace(':','').ToLower()
    $AccountPath = $Account.LocalPath -replace "^.*Users", "\\$($ComputerName)\$($DriveLetter)$\Users"
    $AccountKey  = "\\$($ComputerName)\HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($AccountSid)"
} catch {
    Write-Log -Message "Failed to query user profile $($UserName) on $($ComputerName)" -Type Error
}

Write-Log -Message "Exporting printer settings..." -Type Warning
Start-Process -FilePath "C:\Windows\System32\spool\tools\PrintBrm.exe" -ArgumentList "-B -S \\$(ComputerName) -F $($UserName).printerexport" -NoNewWindow -Wait

if (-not (Test-Path -Path $AccountKey)) {
    Write-Log -Message "$($AccountKey) does not exist" -Type Error
} else {
    Write-Log -Message "Backing up user profile registry hive..." -Type Warning
    Start-Process -FilePath 'reg.exe' -ArgumentList "export $($AccountKey) \\$($ComputerName)\$($DriveLetter)$\$(UserName).reg /y" -NoNewWindow -Wait
    Write-Log -Message "Done." -Type Information

    Write-Log -Message "Removing user profile registry hive..." -Type Warning
    Remove-Item -Path $AccountKey -Recurse -Force
    Write-Log -Message "Done." -Type Information
}

if (-not (Test-Path -Path $AccountPath)) {
    Write-Log -Message "$($AccountPath) does not exist" -Type Error
} else {
    Write-Log -Message "Renaming user profile directory..." -Type Warning
    Rename-Item -Path $AccountPath -NewName "$($UserName).$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')" -Force
    Write-Log -Message "Done." -Type Information
}
