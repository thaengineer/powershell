$regKey       = "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Search"

New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value "0" -PropertyType Dword -Force
New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value "0" -PropertyType Dword -Force
New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value "0" -PropertyType Dword -Force
New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value "0" -PropertyType Dword -Force
New-ItemProperty "HKLM:\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value "1" -PropertyType Dword -Force
if (! (Test-Path $regKey )) { New-Item $regKey -Force | Out-Null }
New-ItemProperty $regKey -Name "SearchboxTaskbarMode"  -Value "0" -PropertyType Dword -Force


########################################
########################################


$profileList  = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*"
$userProfiles = (Get-ItemProperty -Path $profileList | Where-Object { $_.PSChildName -match "S-1-5-21-(\d+-?){4}$" }).PSChildName


foreach($userProfile in $userProfiles) {
    if (Test-Path -Path "HKU:\${userProfile}") {
        $regKey = "HKU:\${userProfile}\Software\Microsoft\Windows\CurrentVersion\Search"

        New-ItemProperty "HKU:\${userProfile}\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value "0" -PropertyType Dword -Force
        New-ItemProperty "HKU:\${userProfile}\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value "0" -PropertyType Dword -Force
        New-ItemProperty "HKU:\${userProfile}\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value "0" -PropertyType Dword -Force
        New-ItemProperty "HKU:\${userProfile}\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value "0" -PropertyType Dword -Force
        New-ItemProperty "HKU:\${userProfile}\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value "1" -PropertyType Dword -Force
        if (! (Test-Path $regKey )) { New-Item $regKey -Force | Out-Null }
        New-ItemProperty $regKey -Name "SearchboxTaskbarMode"  -Value "0" -PropertyType Dword -Force
    }
}
