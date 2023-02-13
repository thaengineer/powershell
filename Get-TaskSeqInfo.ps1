param
(
    [parameter(mandatory=$True)]
    [string]$TaskSequence,

    [parameter(mandatory=$False)]
    [string]$SiteCode,

    [parameter(mandatory=$False)]
    [string]$ProviderMachineName
)


$SiteCode = "<SITE_CODE>"
$ProviderMachineName = "<SCCM_FQDN>"

$initParams = @{}

if ((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

Set-Location "$($SiteCode):\" @initParams


$Ts = Get-CMTaskSequence -Name $TaskSequence -Fast
$TsSteps = ($Ts | Get-CMTaskSequenceGroup | Select * | Where { $_.Name -eq "Install Operating System" }).Steps.Name

foreach ($Step in $TsSteps) {
        foreach ($item in ($TS | Get-CMTaskSequenceStep | Select * | Where { $_.Name -eq $Step } | Select Properties)) {
            $Object = New-Object PSObject -Property @{
                StepName  = $item.Properties.Name
                StepState = $item.Properties.Enabled
            }
            $Object | Select StepName, StepState
    }
}
