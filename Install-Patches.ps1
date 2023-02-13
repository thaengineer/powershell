<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>


param
(
    [parameter(mandatory=$True)]
    [string]$ServersFile,

    [parameter(mandatory=$True)]
    [string]$PatchesDirectory
)


$Servers = Get-Content -Path $ServersFile
$code    = {
    Get-ChildItem -Path "C:\Temp\patches\*.msu" | ForEach-Object { wusa $_.FullName /quiet /norestart }
}

# copy patches to each server and install them
foreach ($Server in $Servers) {
    Copy-Item -Path $PatchesDirectory\*.msu -Destination \\$Server\c$\Temp\patches\ -Recurse
    Invoke-Command -ComputerName $Server -ScriptBlock $code
    Remove-Item -Path \\$Server\Temp\patches\*.msu -Recurse
}
