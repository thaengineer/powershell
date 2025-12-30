Import-Module -Name PSMSI

$UpgradeCode = (New-Guid).Guid.ToUpper()

New-Installer -ProductName "Liquit Collection Member Mgmt" -UpgradeCode $UpgradeCode -Manufacturer 'Gulfstream' -Content {
    New-InstallerDirectory -PredefinedDirectoryName 'ProgramFilesFolder' -Content {
        New-InstallerDirectory -DirectoryName "Liquit Collection Member Mgmt" -Id 'InstallDir' -Content {
            New-InstallerFile -Source '.\Layout.xaml'
            New-InstallerFile -Source '.\LiquitCollectionMemberMgmt.exe' -Id "Main"
        }
    }
    New-InstallerDirectory -PredefinedDirectory 'DesktopFolder' -Content {
        New-InstallerShortcut -Name "Liquit Collection Member Mgmt" -FileId "Main" -WorkingDirectoryId 'InstallDir' -IconPath '.\icon.ico'
    }
} -OutputDirectory (Join-Path $PSScriptRoot "setup")
