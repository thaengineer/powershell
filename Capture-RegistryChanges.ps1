param
(
    [parameter(mandatory=$True)]
    [string]$SetupFile,

    [parameter(mandatory=$True)]
    [string]$Arguments
)

$regHives = @(
    "HKLM",
    "HKCU",
    "HKCR",
    "HKU",
    "HKCC"
)


foreach ($regHive in $regHives) {
    Get-ChildItem -Path "${regHive}:\" -Recurse | Get-ItemProperty | Out-File -FilePath "${regHive}_pre.txt"
}

Start-Process -FilePath "" -ArgumentList "" -NoNewWindow -Wait

foreach ($regHive in $regHives) {
    Get-ChildItem -Path "${regHive}:\" -Recurse | Get-ItemProperty | Out-File -FilePath "${regHive}_post.txt"
}

# this part needs work
foreach ($regHive in $regHives) {
    $diffHKLM = Compare-Object -ReferenceObject $preHKLM -DifferenceObject $postHKLM -Property PSChildName, PSParentPath, Name, Property
    $diffHKLM | Out-File -FilePath "${regHive}_diff.txt"
}


##########


# take a snapshot of the current registry
$preHKLM = Get-ChildItem -Path HKLM:\ -Recurse | Get-ItemProperty
$preHKCU = Get-ChildItem -Path HKCU:\ -Recurse | Get-ItemProperty
$preHKCR = Get-ChildItem -Path HKCR:\ -Recurse | Get-ItemProperty
$preHKU  = Get-ChildItem -Path HKU:\ -Recurse | Get-ItemProperty
$preHKCC = Get-ChildItem -Path HKCC:\ -Recurse | Get-ItemProperty

# install the application you want to capture changes for
Start-Process -FilePath "" -ArgumentList "" -NoNewWindow -Wait

# Take a snapshot of the registry after the installation
$postHKLM = Get-ChildItem -Path HKLM:\ -Recurse | Get-ItemProperty
$postHKCU = Get-ChildItem -Path HKLM:\ -Recurse | Get-ItemProperty
$postHKCR = Get-ChildItem -Path HKLM:\ -Recurse | Get-ItemProperty
$postHKU  = Get-ChildItem -Path HKLM:\ -Recurse | Get-ItemProperty
$postHKCC = Get-ChildItem -Path HKLM:\ -Recurse | Get-ItemProperty

# compare the two snapshots to find the changes
$diffHKLM = Compare-Object -ReferenceObject $preHKLM -DifferenceObject $postHKLM -Property PSChildName, PSParentPath, Name, Property
$diffHKCU = Compare-Object -ReferenceObject $preHKCU -DifferenceObject $postHKCU -Property PSChildName, PSParentPath, Name, Property
$diffHKCR = Compare-Object -ReferenceObject $preHKCR -DifferenceObject $postHKCR -Property PSChildName, PSParentPath, Name, Property
$diffHKU  = Compare-Object -ReferenceObject $preHKU -DifferenceObject $postHKU -Property PSChildName, PSParentPath, Name, Property
$diffHKCC = Compare-Object -ReferenceObject $preHKCC -DifferenceObject $postHKCC -Property PSChildName, PSParentPath, Name, Property

# output the changes to a file
$diffHKLM | Out-File -FilePath "HKLM_diff.txt"
$diffHKCU | Out-File -FilePath "HKCU_diff.txt"
$diffHKCR | Out-File -FilePath "HKCR_diff.txt"
$diffHKU | Out-File -FilePath "HKU_diff.txt"
$diffHKCC | Out-File -FilePath "HKLCC_diff.txt"
