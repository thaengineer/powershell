<#
.SYNOPSIS
    Create a Hyper-V Virtual Machine

.DESCRIPTION
    Updated: 02/07/2023

.NOTES
    N/A

.EXAMPLE
    Create-VM.ps1 -VMName <VM_NAME> -Memory 2GB -DiskSpace 64GB
#>

param
(
    [parameter(mandatory=$True)]
    [string]$VMName,

    [parameter(mandatory=$False)]
    [string]$Memory,

    [parameter(mandatory=$False)]
    [string]$DiskSpace
)


$DiskSize = 127GB

New-VM -Name $VMName -NewVHDSizeBytes 128GB -Path $MachinePath -NewVHDPath "$DiskPath\$VMName.vhdx" -Generation $Generation -SwitchName $SwitchName

try {
    Write-Host "[+] Creating Hyper-V Virtual Machine ${VMName}..."
    New-VM -Name ${VMName} -MemoryStartupBytes ${Memory} -BootDevice "CD" -SwitchName "Bridged" -NewVHDPath "D:\VHD\${VMName}.vhdx" -NewVHDSizeBytes ${DiskSpace} -Path "D:\" -Generation 2

    # enable TPM
    Set-VMkeyProtector -VMName ${VMName} -NewLocalKeyProtector | Out-Null -ErrorAction Stop
    Enable-VMTPM -VMName ${VMName} -ErrorAction Stop

    # set cpu and memory specs
    Set-VMProcessor ${VMName} -Count 2 -ErrorAction Stop
    Set-VMMemory ${VMName} -DynamicMemoryEnabled $true -MinimumBytes 512MB -MaximumBytes ${Memory} -StartupBytes 2GB -ErrorAction Stop

    # enable guest services
    Enable-VMIntegrationService -VMName ${VMName} -Name "Guest Service Interface"

    Write-Host "[+] Done."
}
catch {
    # Write-Host "error: unable to create ${VMName}"
    Write-Error $_.Exception.Message
}
