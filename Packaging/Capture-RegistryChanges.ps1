param
(
    [parameter(mandatory=$True)]
    [string]$SetupFile,

    [parameter(mandatory=$True)]
    [string]$Arguments
)


$Hives = @(
    "HKLM",
    "HKCU",
    "HKCR",
    "HKU",
    "HKCC"
)


foreach($Hive in $Hives) {
    try {
        # take a snapshot of the current registry
        $preCap = Get-ChildItem -Path ${Hive}:\ -Recurse | Get-ItemProperty

        # install the application you want to capture changes for
        Start-Process -FilePath $SetupFile -ArgumentList $Arguments -NoNewWindow -Wait

        # Take a snapshot of the registry after the installation
        $postCap = Get-ChildItem -Path ${Hive}:\ -Recurse | Get-ItemProperty

        # compare the two snapshots to find the changes
        $diff = Compare-Object -ReferenceObject $preCap -DifferenceObject $postCap -Property PSChildName, PSParentPath, Name, Property

        # output the changes to a file
        $diff | Out-File -FilePath "${Hive}_diff.txt"
    } catch {
        Write-Host "error: changes for ${Hive} not captured correctly."
    }
}
