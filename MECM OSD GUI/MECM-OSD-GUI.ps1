Add-Type -AssemblyName PresentationFramework
# [void][System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework")

$XamlPath = ""

if (! (Test-Path -Path $XamlPath)) {
    Write-Host "error: XAML file not found"
    exit(1)
} else {
    [xml]$Xaml  = Get-Content -Path $XamlPath
}

[xml]$Xaml = @'
<Window Name = "Window"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MECM OSD GUI 2023.02"
        Height="510"
        Width="760"
        ResizeMode="NoResize"
        FontSize="14"
        FontWeight="Bold"
        WindowStartupLocation="CenterScreen"
        Topmost="True">
    <Grid Name="Grid">
        <ComboBox Name="LocaleComboBox" HorizontalAlignment="Left" Height="42" Margin="151,147,0,0" VerticalAlignment="Top" Width="479"/>
        <TextBox Name="ComputerNameTextBox" HorizontalAlignment="Left" Height="38" Margin="151,53,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="479" BorderThickness="5" FontSize="14" FontWeight="Bold" MaxLength="15"/>
        <ComboBox Name="KeyboardComboBox" HorizontalAlignment="Left" Height="42" Margin="151,239,0,0" VerticalAlignment="Top" Width="479"/>
        <ComboBox Name="TimeZoneComboBox" HorizontalAlignment="Left" Height="42" Margin="151,334,0,0" VerticalAlignment="Top" Width="479"/>
        <Button Name="OkButton" Content="OK" HorizontalAlignment="Left" Height="42" Margin="315,409,0,0" VerticalAlignment="Top" Width="123" FontWeight="Bold" FontSize="14"/>
        <Label Name="ComputerNameLabel" Content="Computer Name:" HorizontalAlignment="Left" Height="30" Margin="149,18,0,0" VerticalAlignment="Top" Width="128" FontWeight="Bold" FontSize="14"/>
        <Label Name="LocaleLabel" Content="Currency and locale:" HorizontalAlignment="Left" Height="30" Margin="151,112,0,0" VerticalAlignment="Top" Width="150" FontWeight="Bold" FontSize="14"/>
        <Label Name="KeyboardLabel" Content="Keyboard layout:" HorizontalAlignment="Left" Height="30" Margin="151,204,0,0" VerticalAlignment="Top" Width="126" FontWeight="Bold" FontSize="14"/>
        <Label Name="TimeZoneLabel" Content="Time zone:" HorizontalAlignment="Left" Height="30" Margin="151,299,0,0" VerticalAlignment="Top" Width="108" FontWeight="Bold" FontSize="14"/>

    </Grid>
</Window>
'@


# load Xaml
$XamlReader = New-Object System.Xml.XmlNodeReader $Xaml
$Form       = [Windows.Markup.XamlReader]::Load($XamlReader)

# get window elements
$Xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name) -Scope Global
}

# event handler functions
function Set-ComputerName {
    $ComputerNameTextBox.Text = $env:COMPUTERNAME
}

# event handlers
$OkButton.Add_Click({Set-ComputerName})


# launch the gui
$Form.ShowDialog() | Out-Null
