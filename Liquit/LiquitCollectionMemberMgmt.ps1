Add-Type -AssemblyName PresentationFramework, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing

try {
    Get-InstalledModule -Name "Liquit.Server.PowerShell" -ErrorAction Stop | Out-Null
} catch {
    Install-Module -Name "Liquit.Server.PowerShell" -Scope CurrentUser -Force
} finally {
    Import-Module -Name "Liquit.Server.PowerShell"
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


# event handler functions
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
    #$Total             = $DeviceList.Items.Count
    #$Count             = 0
    $Collection        = Get-LiquitDeviceCollection -Name $CollsList.SelectedItem
    $CollectionMembers = Get-LiquitDeviceCollectionMember -DeviceCollection $Collection
    $ProgressBar.Value = 0

    for ($i = 1; $i -le $DeviceList.Items.Count; $i++) {
        $Pct    = $i / $DeviceList.Items.Count * 100
        #Write-Host "[$([Math]::Round($Pct, 0))/100]"
        $Device = Get-LiquitDevice -Name $_ -ErrorAction SilentlyContinue

        if ($null -eq $Device) {
            # Write-Log -Message "[ERROR] $($_) (does not exist)" -LogFile $LogFile
        } elseif ($null -ne $Device -and $_ -notin $CollectionMembers.Name) {
            Add-LiquitDeviceCollectionMember -DeviceCollection $Collection -Device $Device -ErrorAction SilentlyContinue
            # Write-Log -Message "[INFO] $($_) (added to $($CollectionName))" -LogFile $LogFile
        } else {
            # Write-Log -Message "[WARN] $($_) (exists in $($CollectionName)" -LogFile $LogFile
        }
        $ProgressBar.Value = $([Math]::Round($Pct, 0))/100
    }

    #$DeviceList.Items | ForEach-Object {
    #    $Count++
    #
    #    $Device = Get-LiquitDevice -Name $_ -ErrorAction SilentlyContinue
    #
    #    if ($null -eq $Device) {
    #        #$Status.Items.Add("[$($Count)/$($Total)] $($_) (does not exist)")
    #        # Write-Log -Message "[ERROR] $($_) (does not exist)" -LogFile $LogFile
    #    } elseif ($null -ne $Device -and $_ -notin $CollectionMembers.Name) {
    #        Add-LiquitDeviceCollectionMember -DeviceCollection $Collection -Device $Device -ErrorAction SilentlyContinue
    #        #$Status.Items.Add("[$($Count)/$($Total)] $($_) (added)")
    #        # Write-Log -Message "[INFO] $($_) (added to $($CollectionName))" -LogFile $LogFile
    #    } else {
    #        #$Status.Items.Add("[$($Count)/$($Total)] $($_) (skipped)")
    #        # Write-Log -Message "[WARN] $($_) (exists in $($CollectionName)" -LogFile $LogFile
    #    }
    #    #$LastIndex = $Status.Items.Count - 1
    #    #$Status.ScrollIntoView($Status.Items[$LastIndex])
    #}

    Select-Collection
}


function Remove-FromCollection {
    $Total             = $DeviceList.Items.Count
    $Count             = 0
    $Collection        = Get-LiquitDeviceCollection -Name $CollsList.SelectedItem
    $CollectionMembers = Get-LiquitDeviceCollectionMember -DeviceCollection $Collection

    $DeviceList.Items | ForEach-Object {
        $Count++

        $Device = Get-LiquitDevice -Name $_ -ErrorAction SilentlyContinue

        if ($null -eq $Device) {
            #$Status.Items.Add("[$($Count)/$($Total)] $($_) (does not exist)")
            # Write-Log -Message "[ERROR] $($_) (does not exist)" -LogFile $LogFile
        } elseif ($null -ne $Device -and $_ -in $CollectionMembers.Name) {
            Remove-LiquitDeviceCollectionMember -DeviceCollection $Collection -Device $Device -ErrorAction SilentlyContinue
            #$Status.Items.Add("[$($Count)/$($Total)] $($_) (removed)")
            # Write-Log -Message "[INFO] $($_) (added to $($CollectionName))" -LogFile $LogFile
        } else {
            #$Status.Items.Add("[$($Count)/$($Total)] $($_) (skipped)")
            # Write-Log -Message "[WARN] $($_) (exists in $($CollectionName)" -LogFile $LogFile
        }
        #$LastIndex = $Status.Items.Count - 1
        #$Status.ScrollIntoView($Status.Items[$LastIndex])
    }

    Select-Collection
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
