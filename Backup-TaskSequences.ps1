Import-Module "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"
Set-Location -Path "S01:\"

$TaskSequences = Get-CMTaskSequence -Fast | Select-Object *
$BackupDir     = "$env:HOMEDRIVE\BACKUP\TaskSequences"
$Date          = Get-Date -Format yyyyMMdd


if (! (Test-Path -Path "$BackupDir\$Date")) {
    New-Item -Path "$BackupDir\$Date)" -ItemType Directory
}

foreach ($TS in $TaskSequences) {
    Export-CMTaskSequence -TaskSequencePackageId $TS.PackageID -ExportFilePath "$BackupDir\$Date\${TS.Name}.zip" -Verbose
}
