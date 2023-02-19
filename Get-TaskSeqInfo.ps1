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

if ($null -eq (Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

Set-Location "$($SiteCode):\" @initParams


$Ts = Get-CMTaskSequence -Name $TaskSequence -Fast
$TsSteps = ($Ts | Get-CMTaskSequenceGroup | Select-Object-Object * | Where-Object { $_.Name -eq "Install Operating System" }).Steps.Name

foreach ($Step in $TsSteps) {
        foreach ($item in ($TS | Get-CMTaskSequenceStep | Select-Object * | Where-Object { $_.Name -eq $Step } | Select-Object Properties)) {
            $Object = New-Object PSObject -Property @{
                StepName  = $item.Properties.Name
                StepState = $item.Properties.Enabled
            }
            $Object | Select-Object StepName, StepState
    }
}
