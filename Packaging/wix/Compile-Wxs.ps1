<#
.SYNOPSIS
    Compile wxs sourcefile into an msi
.DESCRIPTION
    Compile-Wxs.ps1 compiles .wxs files (WiX Toolset Files) files into an .msi (Microsoft Installer).
.NOTES
    Object files will be created in .\obj\ and executables in .\bin\
.EXAMPLE
    Compile-Wxs.ps1 -WxsFile <FireFox>.wxs

    This will result in the following:
    bin\setup.msi
#>

param (
    [parameter(Mandatory = $true, Position = 0)]
    [string]$WxsFile,

    [parameter(Mandatory = $false, Position = 1)]
    [string]$WixDir = 'C:\Program Files (x86)\WiX Toolset v3.11\bin'
)

if (-not (Test-Path -Path $WixDir)) {
    Write-Host -ForegroundColor Yellow "[!] $($WixDir) does not exist, please specify -WixDir <PATH_TO_WIX_BIN>"
    break
}

Start-Process -FilePath "$($WixDir)\candle.exe" -ArgumentList "$($WxsFile) -o obj\" -NoNewWindow -Wait
Start-Process -FilePath "$($WixDir)\light.exe" -ArgumentList "obj\$($WxsFile).wixobj -o bin\setup.msi" -NoNewWindow -Wait
