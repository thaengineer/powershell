Param (
    [string]$Path = ''
)

if (-not (Test-Path -Path $Path)) {
    return
}

$DomainGroup = '<domain>\<group>'
$Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList "$($DomainGroup)"

$Items = Get-ChildItem -Path "$($Path)"

$Items | Foreach-Object {
    $Acl = $null
    $Acl = Get-Acl -Path $_.FullName
    $Acl.SetOwner($Account)
    $AccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule($Account, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $Acl.SetAccessRule($AccessRule)
    Set-Acl -Path $_.FullName -AclObject $Acl
}
