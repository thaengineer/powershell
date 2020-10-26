Import-Module ActiveDirectory

$profileList = "\HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\"
$machines = get-content ".\machines.txt"

foreach($i in $machines)
{
    if(test-connection -computername $i -count 1 -quiet)
    {
    	$loggedInUser = (gwmi -class win32_computersystem -computername $i | select username).username -split "GAC\\"
    	$userIDs = (ls -Path \\$i\c$\Users).name -notlike "Default" -notlike "Public" -notlike $loggedInUser[1]

    	foreach($id in $userIDs)
    	{
	        try
	        {
	        	$sid = (get-aduser -Identity "$id").sid.value
	        	$key = "\\" + $i + $profileList + $sid
	        	$profilePath = "\\" + $i + "\c$\Users\" + $id
	        	write-host $key
	        	try
	        	{
	        		write-host -foregroundcolor green "[+] Removing $sid from registry on $i..."
	        		reg delete $key /f
	        		write-host -foregroundcolor green "[+] Removing C:\Users\$id from $i..."
	        		remove-item -path $profilePath -Recurse -Force #-verbose
                    write-host ""
	        	}
	        	catch
	        	{
	        		write-host -foregroundcolor red "[!] Unable to remove $sid from $i"
	        	}
	        }
	        catch
	        {
	        	$profilePath = "\\" + $i + "\c$\Users\" + $id
                write-host -foregroundcolor red "[!] No SID found for user ID $id on $i"
                write-host -foregroundcolor green "[+] Removing C:\Users\$id from $i..."
                remove-item -path $profilePath -Recurse -Force #-verbose
	        }
	    }
    }
}
