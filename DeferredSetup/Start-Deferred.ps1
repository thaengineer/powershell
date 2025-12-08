Import-Module -Name ".\modules\ToastHelper.psm1"

$Deferrals = 3
$Title     = "Software Deployment"
$Message   = "Mozilla Firefox ESR 140.5 is scheduled to be installed. Would you like to install it now or defer?"
#$MyInvocation.MyCommand.Path


while ($Deferrals[-1] -ge 0) {
    $Deferrals = Show-Notification -Title $Title -Message $Message -Duration 10 -Deferrals $Deferrals[-1]
}
