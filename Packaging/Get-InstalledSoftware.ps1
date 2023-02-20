Param
(
    [parameter(mandatory=$True)]
    [string]$ComputerName,

    [parameter(mandatory=$False)]
    [string]$Software
)


$X86       = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$X64       = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$codeBlock = {
    $Properties = Get-ChildItem -Path $X86, $X64 | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString
    $SortedList = $Properties | Sort-Object -Unique -Property DisplayName
    #$UserName   = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName.Split("\")[1]
    #$SID        = (Get-ADUser -Identity $UserName).SID.Value
    return $SortedList
}


if(! (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
    Write-Host -ForegroundColor Red "${ComputerName}: not reachable"
} else {
    if($Software -ne "") {
        try {
            Write-Host -ForegroundColor Green "${ComputerName}: searching for ${Software}"
            $SWList = Invoke-Command -ComputerName $ComputerName -ScriptBlock $codeBlock
            $SWList | Where-Object { $_.DisplayName -match $Software }
        } catch {
            Write-Host -ForegroundColor Red "${ComputerName}: unable to establish PSSession"
        }
    } else {
        try {
            Write-Host -ForegroundColor Green "${ComputerName}: compiling full software list"
            $SWList = Invoke-Command -ComputerName $ComputerName -ScriptBlock $codeBlock
            $SWList
        } catch {
            Write-Host -ForegroundColor Red "${ComputerName}: unable to establish PSSession"
        }
    }
}
