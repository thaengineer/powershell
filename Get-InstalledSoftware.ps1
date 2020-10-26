param
(
    [parameter(mandatory=$True)]
    [string]$ComputerName,

    [parameter(mandatory=$False)]
    [string]$Software
)


$scriptblock = {

$loggedInUser = (gwmi -class win32_computersystem | select username).username -split "GAC\\"
$userID = $loggedInUser[1]
# $userSID = (get-aduser -identity $userID).sid.value
#$32CurrentUserPath = "HKU:\" + $userSID + "\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
#$64CurrentUserPath = "HKU:\" + $userSID + "\Software\Microsoft\Windows\CurrentVersion\Uninstall"

$32bit = test-path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$64bit = test-path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
#$32bitCU = test-path $32CurrentUserPath
#$64bitCU = test-path $64CurrentUserPath
$swlist = $()

if($32bit)
{
    $swlist += get-itemproperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | select-object displayname | where {$_.displayname -gt 0 }
}

if($64bit)
{
    $swlist += get-itemproperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | select-object displayname | where {$_.displayname -gt 0 }
}

if($32bitCU)
{
    $swlist += get-itemproperty "HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | select-object displayname | where {$_.displayname -gt 0 }
}

if($64bitCU)
{
    $swlist += get-itemproperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | select-object displayname | where {$_.displayname -gt 0 }
}

$swlist = $swlist | sort -property displayname
return $swlist
}


if(test-connection -computername $computername -count 1 -quiet)
{
    if($Software -ne "")
	{
		write-host -foregroundcolor green "[+] Querying $Software on $computername."
		$result = invoke-command -computername $computername -scriptblock $scriptblock
		$result.displayname | select-string $Software
	}
	else
	{
		write-host -foregroundcolor green "[+] Querying software list on $computername."
		$result = invoke-command -computername $computername -scriptblock $scriptblock
		$result.displayname
	}
}
else
{
    write-host -foregroundcolor red "[!] $computername is currently offline."
}
