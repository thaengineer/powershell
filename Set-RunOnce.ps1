param
(
    [parameter(mandatory=$True)]
    [string]$Executable
)


Write-Host "Adding file to RunOnce registry key."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name 1 -Value "${Executable}" -Type String
