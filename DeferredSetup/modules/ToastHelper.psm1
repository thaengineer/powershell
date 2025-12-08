function Show-Notification {
    param(
        [string]$Title   = "Software Deployment",
        [string]$Message = "PRODUCT_NAME is scheduled to be installed. Would you like to install it now or defer?",
        [int]$Duration   = 60,
        [int]$Deferrals  = 3
    )

    Add-Type -AssemblyName PresentationFramework, System.Windows.Forms, WindowsBase

    $DeferralsRef = [ref]$Deferrals

    $window                       = [System.Windows.Window]::new()
    $window.WindowStyle           = 'None'
    $window.AllowsTransparency    = $true
    $window.Background            = 'Transparent'
    $window.ResizeMode            = 'NoResize'
    $window.Width                 = 420
    $window.Height                = 160
    $window.WindowStartupLocation = 'Manual'
    if ($DeferralsRef.Value -le 0) { $window.Topmost = $true } else { $window.Topmost = $false }

    $screen       = [System.Windows.SystemParameters]::PrimaryScreenWidth
    $screenHeight = [System.Windows.SystemParameters]::PrimaryScreenHeight

    # working area (excludes taskbar)
    $workWidth  = [System.Windows.SystemParameters]::WorkArea.Width
    $workHeight = [System.Windows.SystemParameters]::WorkArea.Height
    $workLeft   = [System.Windows.SystemParameters]::WorkArea.Left
    $workTop    = [System.Windows.SystemParameters]::WorkArea.Top

    # position in bottom-right of display
    $margin      = 20
    $window.Left = $workLeft + $workWidth  - $window.Width  - $margin
    $window.Top  = $workTop  + $workHeight - $window.Height - $margin

    # build the ui
    $border              = [System.Windows.Controls.Border]::new()
    $border.CornerRadius = 12
    $border.Background   = "#1e1e2e"
    $border.Padding      = "15,10,5,10"

    $stack = [System.Windows.Controls.StackPanel]::new()
    $stack.Margin = "2,2,2,2"

    $titleText            = [System.Windows.Controls.TextBlock]::new()
    $titleText.Text       = $Title
    $titleText.FontWeight = 'Bold'
    $titleText.Foreground = 'White'
    $titleText.FontSize   = 16

    $msgText              = [System.Windows.Controls.TextBlock]::new()
    $msgText.Text         = "$Message"
    $msgText.Foreground   = 'White'
    $msgText.FontSize     = 14
    $msgText.TextWrapping = 'Wrap'
    $msgText.Margin       = "0,5,0,5"

    $msgText1              = [System.Windows.Controls.TextBlock]::new()
    $msgText1.Text         = "Deferrals: $($DeferralsRef.Value)"
    $msgText1.FontSize     = 14
    $msgText1.FontWeight   = 'SemiBold'
    $msgText1.TextWrapping = 'Wrap'
    if ($DeferralsRef.Value -gt 0) { $msgText1.Foreground = 'Red' } else { $msgText1.Foreground = "#4c4f69" }

    $stack.Children.Add($titleText) | Out-Null
    $stack.Children.Add($msgText) | Out-Null
    $stack.Children.Add($msgText1) | Out-Null

    # Buttons
    $buttonStack                     = [System.Windows.Controls.StackPanel]::new()
    $buttonStack.Orientation         = 'Horizontal'
    $buttonStack.HorizontalAlignment = 'Right'
    $buttonStack.Margin              = "0,10,0,0"

    $installBtn            = [System.Windows.Controls.Button]::new()
    $installBtn.Content    = "Install Now"
    $installBtn.Width      = 100
    $installBtn.Height     = 28
    $installBtn.Margin     = "0,0,10,0"
    $installBtn.Background = "#dce0e8"
    $installBtn.Foreground = "#4c4f69"
    $installBtn.FontWeight = 'SemiBold'
    $installBtn.FontSize   = "14"

    if ($DeferralsRef.Value -gt 0) {
        $deferBtn            = [System.Windows.Controls.Button]::new()
        $deferBtn.Content    = "Defer"
        $deferBtn.Width      = 100
        $deferBtn.Height     = 28
        $deferBtn.Margin     = "0,0,10,0"
        $deferBtn.Background = "#4c4f69"
        $deferBtn.Foreground = "#dce0e8"
        $deferBtn.FontWeight = 'SemiBold'
        $deferBtn.FontSize   = "14"

        $buttonStack.Children.Add($deferBtn) | Out-Null
    }

    $buttonStack.Children.Add($installBtn) | Out-Null
    $stack.Children.Add($buttonStack) | Out-Null

    $border.Child   = $stack
    $window.Content = $border

    # handlers
    $handler_defer = {
        $timer.Stop()
        if ($DeferralsRef.Value -ge 0) {
            $DeferralsRef.Value--
            #$msgText1.Text = "Deferrals: $($DeferralsRef.Value)"
        }
        $window.Close()
    }

    $handler_install = {
        $timer.Stop()
        $DeferralsRef.Value = -1
        .\setup.ps1
        $window.Close()
    }

    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromSeconds(1)

    $endTime = (Get-Date).AddSeconds($Duration)

    $timer.Add_Tick({
        $remaining = $endTime - (Get-Date)
        $ts = [TimeSpan]::FromSeconds([Math]::Floor($remaining.TotalSeconds))

        if ($remaining.TotalSeconds -le 0) {
            $timer.Stop()
            if ($DeferralsRef.Value -gt 0) {
                $DeferralsRef.Value--
                $msgText1.Text = "Deferrals: $($DeferralsRef.Value) ($($ts.ToString('mm\:ss')))"
            } else {
                $DeferralsRef.Value = -1
                .\setup.ps1
            }
            $window.Close()
        } else {
            $msgText1.Text = "Deferrals: $($DeferralsRef.Value) ($($ts.ToString('hh\:mm\:ss')))"
        }
    })

    $timer.Start()
    # Force immediate display of the full starting time
    $remaining = $endTime - (Get-Date)
    $ts = [TimeSpan]::FromSeconds([Math]::Floor($remaining.TotalSeconds))
    $msgText1.Text = "Deferrals: $($DeferralsRef.Value) ($($ts.ToString('hh\:mm\:ss')))"

    # button actions
    if ($DeferralsRef.Value -gt 0) {
        $deferBtn.add_Click($handler_defer)
    }

    $installBtn.add_Click($handler_install)

    # show window
    $window.ShowDialog()

    return $DeferralsRef.Value[-1]
}
