# Add-Type -AssemblyName PresentationFramework
# Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing

try {
    Get-InstalledModule -Name "Liquit.Server.PowerShell" -ErrorAction Stop | Out-Null
} catch {
    Install-Module -Name "Liquit.Server.PowerShell" -Scope CurrentUser -Force
} finally {
    Import-Module -Name "Liquit.Server.PowerShell"
}

# create log dir
if (-not (Test-Path -Path 'C:\Temp')) {
    New-Item -ItemType Directory -Path 'C:\Temp' | Out-Null
}

# load Layout.xaml
$XamlPath  = "Layout.xaml"
[xml]$Xaml = Get-Content -Path "$XamlPath"

# read Layout.xaml
$XamlReader = New-Object System.Xml.XmlNodeReader $Xaml
$Form       = [Windows.Markup.XamlReader]::Load($XamlReader)

# get window elements
$Xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name) -Scope Global
}

# liquit api connection
$LiquitUri   = ''
$UserName    = ''
$Password    = ConvertTo-SecureString -String '' -AsPlainText -Force
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $Password

try {
    Connect-LiquitWorkspace -URI $LiquitURI -Credential $Credentials -ErrorAction Stop | Out-Null
} catch {
    Write-Host -ForegroundColor Red "Invalid credentials or athentication method."
    return
}

$script:SelectedCollectionName = $null


# event handler functions
function Write-Log {
    param (
        [string]$Message,
        [string]$LogFile
    )

    $TimeStamp = Get-Date -Format "[yyyy-MM-dd HH:mm:ss]"

    Add-Content -Path $LogFile -Value "$($TimeStamp) $($Message)" -Force -ErrorAction SilentlyContinue
}


function Update-Collections {
    # poulate list with collections
    $CollsList.Items.Clear()
    $Collections = (Get-LiquitDeviceCollection).Name
    $Collections | Sort-Object | ForEach-Object {
        $CollsList.Items.Add($_) | Out-Null
    }
}


function Select-Collection {
    if ($null -eq $CollsList.SelectedItem) {
        return
    } else {
        $Collection = Get-LiquitDeviceCollection -Name $CollsList.SelectedItem
        $Devices    = (Get-LiquitDeviceCollectionMember -DeviceCollection $Collection).Name

        $MembersList.Items.Clear()
        #$DeviceList.Items.Clear()
        #$TextFile.Text = $null

        $Devices | Sort-Object | ForEach-Object {
            $MembersList.Items.Add($_)
        }

        $script:SelectedCollectionName = $CollsList.SelectedItem
    }
}


function Select-ComputerList {
    $OpenFileDialog                  = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $OpenFileDialog.Filter           = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $OpenFileDialog.FilterIndex      = 2
    $OpenFileDialog.Title            = "Select a File"

    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $FilePath = $OpenFileDialog.FileName
        $TextFile.Text = $FilePath.Split('\')[-1]

        $DeviceList.Items.Clear()
        Get-Content -Path $filePath | ForEach-Object {
            $DeviceList.Items.Add($_)
        }
    }
}


function Add-ToCollection {
    if ([string]::IsNullOrWhiteSpace($script:SelectedCollectionName)) {
        return
    }

    $Collection        = Get-LiquitDeviceCollection -Name $script:SelectedCollectionName # $CollsList.SelectedItem
    $CollectionMembers = Get-LiquitDeviceCollectionMember -DeviceCollection $Collection
    $LogFile           = "C:\Temp\$($Collection.Name)-add.log"
    $ProgressBar.Value = 0

    for ($i = 1; $i -le $DeviceList.Items.Count; $i++) {
        $Pct    = $i / $DeviceList.Items.Count * 100
        $Device = Get-LiquitDevice -Name $DeviceList.Items[$i - 1] -ErrorAction SilentlyContinue

        if ($null -eq $Device) {
            Write-Log -Message "[ERROR] $($DeviceList.Items[$i - 1]) (does not exist)" -LogFile $LogFile
        } elseif ($null -ne $Device -and $DeviceList.Items[$i - 1] -notin $CollectionMembers.Name) {
            Add-LiquitDeviceCollectionMember -DeviceCollection $Collection -Device $Device -ErrorAction SilentlyContinue
            Write-Log -Message "[INFO] $($DeviceList.Items[$i - 1]) (added to $($Collection.Name))" -LogFile $LogFile
        } else {
            Write-Log -Message "[WARN] $($DeviceList.Items[$i - 1]) (exists in $($Collection.Name))" -LogFile $LogFile
        }
        $ProgressBar.Value = $([Math]::Round($Pct, 0))
        $ProgressBar.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render, [action]{})
        Select-Collection
    }
    $ProgressBar.Value = 0
}


function Remove-FromCollection {
    if ([string]::IsNullOrWhiteSpace($script:SelectedCollectionName)) {
        return
    }

    $Collection        = Get-LiquitDeviceCollection -Name $script:SelectedCollectionName # $CollsList.SelectedItem
    $CollectionMembers = Get-LiquitDeviceCollectionMember -DeviceCollection $Collection
    $LogFile           = "C:\Temp\$($Collection.Name)-remove.log"
    $ProgressBar.Value = 0

    for ($i = 1; $i -le $DeviceList.Items.Count; $i++) {
        $Pct    = $i / $DeviceList.Items.Count * 100
        $Device = Get-LiquitDevice -Name $DeviceList.Items[$i - 1] -ErrorAction SilentlyContinue

        if ($null -eq $Device) {
            Write-Log -Message "[ERROR] $($DeviceList.Items[$i - 1]) (does not exist)" -LogFile $LogFile
        } elseif ($null -ne $Device -and $DeviceList.Items[$i - 1] -in $CollectionMembers.Name) {
            Remove-LiquitDeviceCollectionMember -DeviceCollection $Collection -Device $Device -ErrorAction SilentlyContinue
            Write-Log -Message "[INFO] $($DeviceList.Items[$i - 1]) (removed from $($Collection.Name))" -LogFile $LogFile
        } else {
            Write-Log -Message "[WARN] $($DeviceList.Items[$i - 1]) (did not exist in $($Collection.Name))" -LogFile $LogFile
        }
        $ProgressBar.Value = $([Math]::Round($Pct, 0))
        $ProgressBar.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render, [action]{})
        Select-Collection
    }
    $ProgressBar.Value = 0
}


function CloseWindow {
    $Form.Close()
}


# event handlers
Update-Collections
$SelectCollBtn.Add_Click({ Select-Collection })
$OpenFile.Add_Click({ Select-ComputerList })
$AddBtn.Add_Click({ Add-ToCollection })
$RemoveBtn.Add_Click({ Remove-FromCollection })

# launch the gui
$Form.ShowDialog() | Out-Null
