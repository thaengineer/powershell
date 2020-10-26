$machines = get-content -path ".\machines.txt"
$bios_pword = "<utf-16/> admin"

foreach($i in $machines)
{
    if(test-connection -computername $i -count 1 -quiet)
    {
        $computer_model = (get-wmiobject -class win32_computersystem -computername $i).model
    
        # List current BIOS settings
        # $bios_settings = (get-wmiobject -namespace root/hp/instrumentedBIOS -class HP_BIOSEnumeration -computername $machine)
        # $bios_settings | Format-Table Name,Value -AutoSize
    
        if($computer_model -eq "HP EliteBook")
        {
	        write-host -foregroundcolor green "Applying BIOS settings..."
	        $bios = (get-wmiobject -namespace root/hp/instrumentedBIOS -class HP_BIOSSettingInterface -computername $i)
    
    	    $bios.SetBIOSSetting('PXE Internal NIC boot', 'Enable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('PXE Internal IPV4 NIC boot', 'Enable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('PXE Internal IPV6 NIC boot', 'Enable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('Wireless Button State', 'Enable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('LAN/WLAN Switching', 'Enable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('Embedded Bluetooth Device', 'Disable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('Fingerprint Device', 'Disable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('Display Diagnostic URL', 'Disable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('Deep S3', 'Off', $bios_pword) # On/Off/Auto
    	    # $bios.SetBIOSSetting('S3 Wake Timer', 'Immediately', $bios_pword)
    	    $bios.SetBIOSSetting('Customized Boot', 'Disable', $bios_pword) # Enable/Disable
    	    $bios.SetBIOSSetting('HP Application', 'Disable', $bios_pword) # Enable/Disable
    
    	    # $bios.SetBIOSSetting('Virtualization Technology (VTx)', 'Enable', $bios_pword) # Enable/Disable
    	    write-host -foregroundcolor green "BIOS settings have been applied, please reboot the target machine."
        	start-sleep -seconds 5
        }
        else
        {
    	    write-host -foregroundcolor red $i "is a" $computer_model "and is not supported by this script, nothing to do..."
            $i | out-file -filepath ".\bios_nosupport.txt" -append
    	    start-sleep -seconds 5
        }
    }
    else
    {
        write-host -foregroundcolor red "Unable to connect to" $i "at this time, nothing to do..."
        $i | out-file -filepath ".\bios_failed.txt" -append
        start-sleep -seconds 5
    }
}
