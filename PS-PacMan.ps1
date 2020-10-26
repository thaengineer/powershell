# PARAMS
param
(
	[parameter(mandatory=$False)]
	[switch]$i,

	[parameter(mandatory=$False)]
	[switch]$r,

	[parameter(mandatory=$False)]
	[switch]$q,

	[parameter(mandatory=$False)]
	[string]$Package,

	[parameter(mandatory=$False)]
	[string]$Target
)


# VARS
$repo = "C:\usr\pkgs\Win7"
$pkgs = (ls $repo).name


# INSTALL
function install()
{
	if(test-connection -computername $Target -count 1 -quiet)
	{
		write-host -foregroundcolor green "[+] $Package will be installed on $Target"
		if(test-path -path "\\$Target\c$\Temp\$Package")
		{
			write-host "[+] Installing..."
			invoke-command -computername $Target -scriptblock { cd C:\Temp\$args; .\install.bat } -argumentlist $Package
			write-host -foregroundcolor green "[+] Done."
		}
		else
		{
			write-host "[+] Copying source files..."
			copy-item -path "$repo\$Package" -destination "\\$Target\c$\Temp" -container -force -recurse
			write-host "[+] Installing..."
			invoke-command -computername $Target -scriptblock { cd C:\Temp\$args; .\install.bat } -argumentlist $Package
			write-host -foregroundcolor green "[+] Done."
		}
	}
	else
	{
		write-host -foregroundcolor red "[!] FAILED: $Target - OFFLINE"
	}
}

# UNINSTALL
function remove()
{
	if(test-connection -computername $Target -count 1 -quiet)
	{
		write-host -foregroundcolor green "[+] Target: $Target"
		write-host -foregroundcolor green "[+] Package: $Package"
		write-host "[+] Copying source files..."
		copy-item -path "$repo\$Package" -destination "\\$Target\c$\Temp" -container -force -recurse
		write-host "[+] Uninstalling..."
		invoke-command -computername $Target -scriptblock { cd C:\Temp\$args; .\uninstall.bat } -argumentlist $Package
		# write-host "[+] Cleaning up..."
		# remove-item -path "\\$Target\c$\Temp\$Package" -recurse
		write-host -foregroundcolor green "[+] Done."
	}
	else
	{
		write-host -foregroundcolor red "[!] FAILED: $Target - OFFLINE"
	}
}


# MAIN
if($i -eq $False -and $r -eq $False -and $q -eq $False)
{
	write-host "psman - Package Manager"
	write-host "`nUsage:"
	write-host "  Install Software"
	write-host "    psman -i [PACKAGE] [TARGET]"
	write-host ""
	write-host "  Uninstall Software"
	write-host "    psman -r [PACKAGE] [TARGET]"
	write-host ""
	write-host "  Query Software"
	write-host "    psman -q [ STRING ]"
	write-host ""
}
elseif($i -eq $True)
{
	install
}
elseif($r -eq $True)
{
	remove
}
elseif($q -eq $True -and $Package -eq "")
{
	$pkgs
}
elseif($q -eq $True -and $Package -ne "")
{
	$pkgs | select-string $Package
}
