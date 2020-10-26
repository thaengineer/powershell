Import-Module -Name activedirectory

# e.g. "OU=abc,DC=xyz,DC=com"
$softwareOU = ""

# button functions
$handler_queryCN = {
	[void] $ListBox1.Items.Clear()
	[void] $ListBox2.Items.Clear()
	[void] $ListBox3.Items.Clear()
	[void] $ListBox4.Items.Clear()
	[void] $TextBox2.Clear()
	$computerName = $TextBox1.Text
	$query = (Get-ADComputer -Identity $computerName -Properties memberof).memberof -replace '^CN=([^,]+).+$','$1' | sort

	foreach($i in $query)
	{
		[void] $ListBox1.Items.Add($i)
	}
}

$handler_querySW = {
	[void] $ListBox2.Items.Clear()
	$softwareName = $TextBox2.Text
	$query = (Get-ADGroup -SearchBase $softwareOU -Filter *).name | sort | select-string $softwareName

	foreach($i in $query)
	{
		[void] $ListBox2.Items.Add($i)
	}
}

$handler_removeSelection = {
	$computer = $TextBox1.Text
	$computerName = Get-ADComputer -Identity $computer

	foreach($i in $ListBox1.selectedItems)
	{
		Remove-ADGroupMember -Identity $i -Members $computerName -ErrorAction silentlyContinue -WarningAction silentlyContinue -confirm:$false
		[void] $ListBox1.Items.Remove($i)
		[void] $ListBox4.Items.Add("[INFO] Removed $i group membership")
	}
}

$handler_removeAll = {
	$computer = $TextBox1.Text
	$computerName = Get-ADComputer -Identity $computer

	foreach($i in $ListBox1.Items)
	{
		Remove-ADGroupMember -Identity $i -Members $computerName -ErrorAction silentlyContinue -WarningAction silentlyContinue -confirm:$false
		[void] $ListBox4.Items.Add("[INFO] Removed $i group membership")
	}
	[void] $ListBox1.Items.Clear()
}

$handler_selectApp = {
	foreach($i in $ListBox2.selectedItems)
	{
		[void] $ListBox3.Items.Add($i)
	}

}

$handler_applyMemberships = {
	$computer = $TextBox1.Text
	$computerName = Get-ADComputer -Identity $computer

	foreach($i in $ListBox3.Items)
	{
		$sw = Get-ADGroup -Identity "$i"
		Add-ADGroupMember -Identity $sw -Members $computerName -ErrorAction silentlyContinue -WarningAction silentlyContinue -confirm:$false
		[void] $ListBox1.Items.Add($i)
		[void] $ListBox4.Items.Add("[INFO] Added $i group membership")
	}
	[void] $ListBox3.Items.Clear()
}

$handler_resetSelection = {
	[void] $ListBox3.Items.Clear()
}

$handler_copyFrom = {
	$computer = $TextBox3.Text
	$computerName = Get-ADComputer -Identity $computer
	if($computer -ne "<COPY FROM>")
	{
		[void] $ListBox3.Items.Clear()
		$query = (Get-ADComputer -Identity $computer -Properties memberof).memberof -replace '^CN=([^,]+).+$','$1' | sort
	}
	elseif($computer -ne "")
	{
		[void] $ListBox3.Items.Clear()
		$query = (Get-ADComputer -Identity $computer -Properties memberof).memberof -replace '^CN=([^,]+).+$','$1' | sort
	}
	else
	{
	}

	foreach($i in $query)
	{
		[void] $ListBox3.Items.Add($i)
	}
}

$handler_exportList = {
	$computer = $TextBox1.Text
	$userprofile = $env:userprofile

	foreach($i in $ListBox1.Items)
	{
		"$i" | out-file -filepath "$userprofile\Desktop\$computer.txt" -append -force -confirm:$false -nonewline
		"`n" |  out-file -filepath "$userprofile\Desktop\$computer.txt" -append -force -confirm:$false
	}
	[void] $ListBox4.Items.Add("[INFO] Exported software list to $userprofile\Desktop\$computer.txt")
}


########################################
########################################

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()


$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '480,560'
$Form.text = "SCCM App Deploy"
$Form.TopMost = $false
$Form.FormBorderStyle = 'Fixed3D'
$Form.StartPosition = "CenterScreen"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Windows\CCM\SCClient.exe')

# buttons
$Button1 = New-Object system.Windows.Forms.Button
$Button1.text = "Select Computer"
$Button1.Name = "Button1"
$Button1.width = 131
$Button1.height = 26
$Button1.location = New-Object System.Drawing.Point(24,30)
$Button1.Font = 'Microsoft Sans Serif,10'
$Button1.add_Click($handler_queryCN)

$Button2 = New-Object system.Windows.Forms.Button
$Button2.text = "Remove Selected"
$Button2.Name = "Button2"
$Button2.width = 131
$Button2.height = 26
$Button2.location = New-Object System.Drawing.Point(24, 80)
$Button2.Font = 'Microsoft Sans Serif,10'
$Button2.add_Click($handler_removeSelection)

$Button3 = New-Object system.Windows.Forms.Button
$Button3.text = "Remove All"
$Button3.Name = "Button3"
$Button3.width = 131
$Button3.height = 26
$Button3.location = New-Object System.Drawing.Point(24, 110)
$Button3.Font = 'Microsoft Sans Serif,10'
$Button3.add_Click($handler_removeAll)

$Button4 = New-Object system.Windows.Forms.Button
$Button4.text = "Search"
$Button4.Name = "Button4"
$Button4.width = 131
$Button4.height = 26
$Button4.location = New-Object System.Drawing.Point(24, 190)
$Button4.Font = 'Microsoft Sans Serif,10'
$Button4.add_Click($handler_querySW)

$Button5 = New-Object system.Windows.Forms.Button
$Button5.text = "Select Application"
$Button5.Name = "Button5"
$Button5.width = 131
$Button5.height = 26
$Button5.location = New-Object System.Drawing.Point(24, 240)
$Button5.Font = 'Microsoft Sans Serif,10'
$Button5.add_Click($handler_selectApp)

$Button6 = New-Object system.Windows.Forms.Button
$Button6.text = "Copy From"
$Button6.Name = "Button6"
$Button6.width = 131
$Button6.height = 26
$Button6.location = New-Object System.Drawing.Point(24, 300)
$Button6.Font = 'Microsoft Sans Serif,10'
$Button6.add_Click($handler_copyFrom)

$Button7 = New-Object system.Windows.Forms.Button
$Button7.text = "Apply List"
$Button7.Name = "Button7"
$Button7.width = 131
$Button7.height = 26
$Button7.location = New-Object System.Drawing.Point(24, 350)
$Button7.Font = 'Microsoft Sans Serif,10'
$Button7.add_Click($handler_applyMemberships)

$Button8 = New-Object system.Windows.Forms.Button
$Button8.text = "Reset List"
$Button8.Name = "Button8"
$Button8.width = 131
$Button8.height = 26
$Button8.location = New-Object System.Drawing.Point(24, 380)
$Button8.Font = 'Microsoft Sans Serif,10'
$Button8.add_Click($handler_resetSelection)

$Button9 = New-Object system.Windows.Forms.Button
$Button9.text = "Export List"
$Button9.Name = "Button9"
$Button9.width = 131
$Button9.height = 26
$Button9.location = New-Object System.Drawing.Point(24, 140)
$Button9.Font = 'Microsoft Sans Serif,10'
$Button9.add_Click($handler_exportList)


# labels
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Location = New-Object System.Drawing.Point(174,12)
$Label1.AutoSize = $True
$Label1.Font = 'Microsoft Sans Serif,10'
$Label1.Text = "Computer Name:"

$Label2 = New-Object System.Windows.Forms.Label
$Label2.Location = New-Object System.Drawing.Point(174,60)
$Label2.AutoSize = $True
$Label2.Font = 'Microsoft Sans Serif,10'
$Label2.Text = "Application Group Memberships:"

$Label3 = New-Object System.Windows.Forms.Label
$Label3.Location = New-Object System.Drawing.Point(174,170)
$Label3.AutoSize = $True
$Label3.Font = 'Microsoft Sans Serif,10'
$Label3.Text = "Search:"

$Label4 = New-Object System.Windows.Forms.Label
$Label4.Location = New-Object System.Drawing.Point(174,220)
$Label4.AutoSize = $True
$Label4.Font = 'Microsoft Sans Serif,10'
$Label4.Text = "Search Results:"

$Label5 = New-Object System.Windows.Forms.Label
$Label5.Location = New-Object System.Drawing.Point(174,330)
$Label5.AutoSize = $True
$Label5.Font = 'Microsoft Sans Serif,10'
$Label5.Text = "Pending Selection:"

$Label6 = New-Object System.Windows.Forms.Label
$Label6.Location = New-Object System.Drawing.Point(24,440)
$Label6.AutoSize = $True
$Label6.Font = 'Microsoft Sans Serif,10'
$Label6.Text = "Console Log:"


# text boxes
$TextBox1 = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline = $false
$TextBox1.width = 279
$TextBox1.height = 30
$TextBox1.location = New-Object System.Drawing.Point(174,32)
$TextBox1.Font = 'Microsoft Sans Serif,10'
$TextBox1.Text = $env:computername

$TextBox2 = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline = $false
$TextBox2.width = 279
$TextBox2.height = 30
$TextBox2.location = New-Object System.Drawing.Point(174,190)
$TextBox2.Font = 'Microsoft Sans Serif,10'
$TextBox2.Text = ""

$TextBox3 = New-Object system.Windows.Forms.TextBox
$TextBox3.multiline = $false
$TextBox3.width = 131
$TextBox3.height = 30
$TextBox3.location = New-Object System.Drawing.Point(24,272)
$TextBox3.Font = 'Microsoft Sans Serif,10'
$TextBox3.Text = "<COPY FROM>"


# list boxes
$ListBox1 = New-Object System.Windows.Forms.ListBox
$ListBox1.width = 279
$ListBox1.height = 96
$ListBox1.Location = New-Object System.Drawing.Point(174,80)
$listBox1.SelectionMode = "MultiExtended"
$ListBox1.Font = 'Microsoft Sans Serif,10'
$ListBox1.HorizontalScrollbar = $true

$ListBox2 = New-Object System.Windows.Forms.ListBox
$ListBox2.width = 279
$ListBox2.height = 96
$ListBox2.Location = New-Object System.Drawing.Point(174,240)
$listBox2.SelectionMode = "MultiExtended"
$ListBox2.Font = 'Microsoft Sans Serif,10'
$ListBox2.HorizontalScrollbar = $true

$ListBox3 = New-Object System.Windows.Forms.ListBox
$ListBox3.width = 279
$ListBox3.height = 96
$ListBox3.Location = New-Object System.Drawing.Point(174,350)
$listBox3.SelectionMode = "MultiExtended"
$ListBox3.Font = 'Microsoft Sans Serif,10'
$ListBox3.HorizontalScrollbar = $true

$ListBox4 = New-Object System.Windows.Forms.ListBox
$ListBox4.width = 430
$ListBox4.height = 96
$ListBox4.Location = New-Object System.Drawing.Point(24,460)
$listBox4.SelectionMode = "MultiExtended"
$ListBox4.Font = 'Microsoft Sans Serif,10'
$ListBox4.HorizontalScrollbar = $true


$elements = @(
	$Button1,
    $Button2,
    $Button3,
    $Button3,
    $Button4,
    $Button5,
    $Button6,
    $Button7,
    $Button8,
    $Button9,
    $Label1,
    $Label2,
    $Label3,
    $Label4,
    $Label5,
    $Label6,
    $TextBox1,
    $TextBox2,
    $TextBox3,
    $ListBox1,
    $ListBox2,
    $ListBox3,
    $ListBox4
)

$Form.controls.AddRange($elements)
[void]$Form.ShowDialog()
