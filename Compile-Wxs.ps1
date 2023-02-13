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


param
(
    [parameter(mandatory=$True)]
    [string]$WxsFile
)

$wixDir = "C:\Program Files (x86)\WiX Toolset v3.11\bin"

& ${wixDir}\candle.exe ${WxsFile} -o obj\
& ${wixDir}\light.exe obj\${WxsFile}.wixobj -o bin\setup.msi
