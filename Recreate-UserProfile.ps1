# command line parameters
param
(
	[parameter(mandatory=$True)]
	[string]$ComputerName,
	
	[parameter(mandatory=$True)]
	[string]$UserId
)


$SID = (get-aduser -Identity "$UserId").sid.value
# $userSID = (Get-WmiObject -Class Win32_UserProfile -ComputerName $comp | Where-Object {$_.LocalPath -eq 'C:\Users\' + $userName}).sid + ".sid"
$userProfile = "\\${ComputerName}\HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\${SID}"
$userDirectory = "\\${ComputerName}\c$\Users\${UserId}"
$count = 1

Write-Host "[+] Exporting printer settings..."
Start-Process -FilePath "C:\Windows\System32\spool\tools\PrintBrm.exe" -ArgumentList "-B -S \\${ComputerName} -F ${UserId}.printerexport" -NoNewWindow -Wait

# check if computer is online
if (! (Test-Connection -computername $ComputerName -count 1 -quiet)) {
	Write-Host -ForegroundColor Red "[!] ${ComputerName} is not reachable."
} else {
	if (! (Test-Path -Path $userProfile)) {
		Write-Host "[!] User Account SID does not exist."
	} else {
		try
		{
			Write-Host "[+] Backing up ${userProfile}"
			reg export ${userProfile} \\${ComputerName}\c$\${UserId}.reg /y

			write-host -foregroundcolor green "[+] Removing ${userProfile}"
			reg delete ${userProfile} /f

			write-host -foregroundcolor green "[+] Registry entry has been removed."
		}
		catch
		{
			write-host -foregroundcolor red "[!] Error removing $userProfile"
		}
	}

	# check if user directory exists and rename it to $UserId.bak, or $UserId.bak1, ...
	if(test-path -path $userDirectory)
	{
		write-host -foregroundcolor green "[+] Renaming - $userDirectory"
		
		while(test-path -path $userDirectory)
		{
			try
			{
				rename-item -path $userDirectory -newname "${UserId}.bak" -force -erroraction silentlycontinue
			}
			catch
			{
				rename-item -path $userDirectory -newname "${UserId}.bak${count}" -force -erroraction silentlycontinue
			}

			$count += 1
		}

		write-host -foregroundcolor green "[+] Renamed."
	}	
	else
	{
		write-host -foregroundcolor red "[!] User profile folder does not exist."
	}
}

