# command line parameters
param
(
	[parameter(mandatory=$True)]
	[string]$ComputerName,
	
	[parameter(mandatory=$True)]
	[string]$UserId
)


# libraries
Import-Module ActiveDirectory


# variables
$sid = (get-aduser -Identity "$UserId").sid.value
$userProfile = "\\" + $ComputerName + "\HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\" + $sid
$userDirectory = "\\" + $ComputerName + "\c$\Users\" + $UserId
$count = 1


# check if computer is online
if(test-connection -computername $ComputerName -count 1 -quiet)
{
	write-host -foregroundcolor green "[+] $ComputerName"

	# check if SID exists in registry and delete it
	if(test-path -path $userProfile)
	{
		try
		{
			write-host -foregroundcolor green "[+] Removing - $userProfile"
			reg delete $userProfile /f
			write-host -foregroundcolor green "[+] Romoved."
		}
		catch
		{
			write-host -foregroundcolor red "[!] Error removing - $userProfile"
		}
	}
	else
	{
		write-host -foregroundcolor red "[!] User account SID does not exist."
	}

	# check if user directory exists and rename it to $UserId.bak, or $UserId.bak1, ...
	if(test-path -path $userDirectory)
	{
		write-host -foregroundcolor green "[+] Renaming - $userDirectory"
		
		while(test-path -path $userDirectory)
		{
			try
			{
				rename-item -path $userDirectory -newname "$UserId.bak" -force -erroraction silentlycontinue
			}
			catch
			{
				rename-item -path $userDirectory -newname "$UserId.bak$count" -force -erroraction silentlycontinue
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

