<#
.SYNOPSIS
    Fetches data from AD users and allows for editing. Additionally, accounts settings and password changes can be made.

.DESCRIPTION
    This script accepts a name (given name, surname or SamAccountName) and displays all users with that name in the 
    table bellow. From this list, a user can then be selected and their user information will be displayed in the text 
    boxes below. These can be edited (with a few exceptions) if necessary. Additionally, a temporary password for the 
    selected user can be set and account settings can be applied.

.NOTES
    To select a user, click on the empty checkbox next to the corresponding given name.

    2024, Gianni Schmidt
#>

#Import necessary libraries
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

#Import AD module
Import-Module ActiveDirectory

#Hide the PowerShell window (C#)
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class User {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@
$HWND = $([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle)
[void][User]::ShowWindow($HWND, 0)  

#Create the main window
$form = New-Object System.Windows.Forms.Form
$form.Text = "AD User Information Center"
$form.Size = New-Object System.Drawing.Size(800,770)
$form.StartPosition = "CenterScreen"

#TextBox for the user search
$textBoxSearch = New-Object System.Windows.Forms.TextBox
$textBoxSearch.Location = New-Object System.Drawing.Point(10,10)
$textBoxSearch.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxSearch)

#Button to search the specified user
$buttonSearch = New-Object System.Windows.Forms.Button
$buttonSearch.Text = "Search"
$buttonSearch.Location = New-Object System.Drawing.Point(220, 10)
$buttonSearch.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($buttonSearch)

#Button to clear the entry
$buttonClear = New-Object System.Windows.Forms.Button
$buttonClear.Text = "Clear Entry"
$buttonClear.Location = New-Object System.Drawing.Point(330, 10)
$buttonClear.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($buttonClear)

#DataGridView to display the found users
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10,40)
$dataGridView.Size = New-Object System.Drawing.Size(760,100)
$dataGridView.AutoSizeColumnsMode = 'Fill'
$dataGridView.ColumnHeadersHeightSizeMode = 'AutoSize'
$form.Controls.Add($dataGridView)

$dataGridView.Columns.Add("GivenName", "Given Name")
$dataGridView.Columns.Add("Surname", "Surname")
$dataGridView.Columns.Add("SamAccountName", "SamAccountName")

#TextBox to display the OU
$textBoxOU = New-Object System.Windows.Forms.TextBox
$textBoxOU.Location = New-Object System.Drawing.Point(10, 150)
$textBoxOU.Size = New-Object System.Drawing.Size(760, 20)
$textBoxOU.ReadOnly = $true 
$form.Controls.Add($textBoxOU)

<#--------------------------------------------------------------------User Information (GUI)-----------------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

#Header - "User Information"
$labelUserData = New-Object System.Windows.Forms.Label
$labelUserData.Text = "User Information"
$labelUserData.Location = New-Object System.Drawing.Point(20, 180)
$labelUserData.Size = New-Object System.Drawing.Size(120, 20)
$labelUserData.Font = New-Object System.Drawing.Font($labelUserData.Font, [System.Drawing.FontStyle]::Underline)
$form.Controls.Add($labelUserData)

#Label - "Surname"
$labelSurname = New-Object System.Windows.Forms.Label
$labelSurname.Text = "Surname"
$labelSurname.Location = New-Object System.Drawing.Point(10, 200)
$labelSurname.Size = New-Object System.Drawing.Size(100, 20)
$labelSurname.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelSurname)

#TextBox - "Surname"
$textBoxSurname = New-Object System.Windows.Forms.TextBox
$textBoxSurname.Location = New-Object System.Drawing.Point(120, 200)
$textBoxSurname.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxSurname)

#Label - "Given Name"
$labelFirstName = New-Object System.Windows.Forms.Label
$labelFirstName.Text = "Given Name"
$labelFirstName.Location = New-Object System.Drawing.Point(10, 230)
$labelFirstName.Size = New-Object System.Drawing.Size(100, 20)
$labelFirstName.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelFirstName)

#TextBox - "Given Name"
$textBoxFirstName = New-Object System.Windows.Forms.TextBox
$textBoxFirstName.Location = New-Object System.Drawing.Point(120, 230)
$textBoxFirstName.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxFirstName)

#Label - "User Name"
$labelUserName = New-Object System.Windows.Forms.Label
$labelUserName.Text = "User Name"
$labelUserName.Location = New-Object System.Drawing.Point(10, 260)
$labelUserName.Size = New-Object System.Drawing.Size(100, 20)
$labelUserName.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelUserName)

#TextBox - "User Name"
$textBoxUserName = New-Object System.Windows.Forms.TextBox
$textBoxUserName.Location = New-Object System.Drawing.Point(120, 260)
$textBoxUserName.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxUserName)

#Label - "Description"
$labelDescription = New-Object System.Windows.Forms.Label
$labelDescription.Text = "Description"
$labelDescription.Location = New-Object System.Drawing.Point(10, 290)
$labelDescription.Size = New-Object System.Drawing.Size(100, 20)
$labelDescription.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelDescription)

#TextBox - "Description"
$textBoxDescription = New-Object System.Windows.Forms.TextBox
$textBoxDescription.Location = New-Object System.Drawing.Point(120, 290)
$textBoxDescription.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxDescription)

#Label - "E-Mail"
$labelEMail = New-Object System.Windows.Forms.Label
$labelEMail.Text = "E-Mail"
$labelEMail.Location = New-Object System.Drawing.Point(10, 320)
$labelEMail.Size = New-Object System.Drawing.Size(100, 20)
$labelEMail.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelEMail)

#TextBox - "E-Mail"
$textBoxEMail = New-Object System.Windows.Forms.TextBox
$textBoxEMail.Location = New-Object System.Drawing.Point(120, 320)
$textBoxEMail.Size = New-Object System.Drawing.Size(200, 20)
$textBoxEMail.ReadOnly = $true
$form.Controls.Add($textBoxEMail)

#Label - "Phone"
$labelPhone = New-Object System.Windows.Forms.Label
$labelPhone.Text = "Phone"
$labelPhone.Location = New-Object System.Drawing.Point(10, 350)
$labelPhone.Size = New-Object System.Drawing.Size(100, 20)
$labelPhone.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelPhone)

#TextBox - "Phone"
$textBoxPhone = New-Object System.Windows.Forms.TextBox
$textBoxPhone.Location = New-Object System.Drawing.Point(120, 350)
$textBoxPhone.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxPhone)

#Label - "Phone 2"
$labelPhone2 = New-Object System.Windows.Forms.Label
$labelPhone2.Text = "Phone 2"
$labelPhone2.Location = New-Object System.Drawing.Point(10, 380)
$labelPhone2.Size = New-Object System.Drawing.Size(100, 20)
$labelPhone2.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelPhone2)

#TextBox - "Phone 2"
$textBoxPhone2 = New-Object System.Windows.Forms.TextBox
$textBoxPhone2.Location = New-Object System.Drawing.Point(120, 380)
$textBoxPhone2.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxPhone2)

#Label - "Mobile"
$labelMobile = New-Object System.Windows.Forms.Label
$labelMobile.Text = "Mobile"
$labelMobile.Location = New-Object System.Drawing.Point(10, 410)
$labelMobile.Size = New-Object System.Drawing.Size(100, 20)
$labelMobile.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelMobile)

#TextBox - "Mobile"
$textBoxMobile = New-Object System.Windows.Forms.TextBox
$textBoxMobile.Location = New-Object System.Drawing.Point(120, 410)
$textBoxMobile.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxMobile)

#Label - "Form of address"
$labelSalute = New-Object System.Windows.Forms.Label
$labelSalute.Text = "Form of Address"
$labelSalute.Location = New-Object System.Drawing.Point(10, 440)
$labelSalute.Size = New-Object System.Drawing.Size(100, 20)
$labelSalute.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelSalute)

#TextBox - "Form of address"
$textBoxSalute = New-Object System.Windows.Forms.TextBox
$textBoxSalute.Location = New-Object System.Drawing.Point(120, 440)
$textBoxSalute.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxSalute)

#Label - "SAP User Name"
$labelSAP = New-Object System.Windows.Forms.Label
$labelSAP.Text = "SAP User Name"
$labelSAP.Location = New-Object System.Drawing.Point(0, 470)
$labelSAP.Size = New-Object System.Drawing.Size(110, 20)
$labelSAP.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelSAP)

#TextBox - "SAP User Name"
$textBoxSAP = New-Object System.Windows.Forms.TextBox
$textBoxSAP.Location = New-Object System.Drawing.Point(120, 470)
$textBoxSAP.Size = New-Object System.Drawing.Size(200, 20)
$textBoxSAP.ReadOnly = $true
$form.Controls.Add($textBoxSAP)

#Label - "Employee ID"
$labelEmployeeID = New-Object System.Windows.Forms.Label
$labelEmployeeID.Text = "Employee ID"
$labelEmployeeID.Location = New-Object System.Drawing.Point(10, 500)
$labelEmployeeID.Size = New-Object System.Drawing.Size(100, 20)
$labelEmployeeID.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelEmployeeID)

#TextBox - "Employee ID"
$textBoxEmployeeID = New-Object System.Windows.Forms.TextBox
$textBoxEmployeeID.Location = New-Object System.Drawing.Point(120, 500)
$textBoxEmployeeID.Size = New-Object System.Drawing.Size(200, 20)
$textBoxEmployeeID.ReadOnly = $true
$form.Controls.Add($textBoxEmployeeID)

#Label - "HOME Directory"
$labelHOME = New-Object System.Windows.Forms.Label
$labelHOME.Text = "HOME Directory"
$labelHOME.Location = New-Object System.Drawing.Point(0, 530)
$labelHOME.Size = New-Object System.Drawing.Size(110, 20)
$labelHOME.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelHOME)

#TextBox - "HOME Directory"
$textBoxHOME = New-Object System.Windows.Forms.TextBox
$textBoxHOME.Location = New-Object System.Drawing.Point(120, 530)
$textBoxHOME.Size = New-Object System.Drawing.Size(200, 20)
$textBoxHOME.ReadOnly = $true
$form.Controls.Add($textBoxHOME)

#Label - "Position"
$labelPosition = New-Object System.Windows.Forms.Label
$labelPosition.Text = "Position"
$labelPosition.Location = New-Object System.Drawing.Point(10, 560)
$labelPosition.Size = New-Object System.Drawing.Size(100, 20)
$labelPosition.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelPosition)

#TextBox - "Position"
$textBoxPosition = New-Object System.Windows.Forms.TextBox
$textBoxPosition.Location = New-Object System.Drawing.Point(120, 560)
$textBoxPosition.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxPosition)

#Label - "Department"
$labelDepartment = New-Object System.Windows.Forms.Label
$labelDepartment.Text = "Department"
$labelDepartment.Location = New-Object System.Drawing.Point(10, 590)
$labelDepartment.Size = New-Object System.Drawing.Size(100, 20)
$labelDepartment.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelDepartment)

#TextBox - "Department"
$textBoxDepartment = New-Object System.Windows.Forms.TextBox
$textBoxDepartment.Location = New-Object System.Drawing.Point(120, 590)
$textBoxDepartment.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxDepartment)

#Label - "Company"
$labelCompany = New-Object System.Windows.Forms.Label
$labelCompany.Text = "Company"
$labelCompany.Location = New-Object System.Drawing.Point(10, 620)
$labelCompany.Size = New-Object System.Drawing.Size(100, 20)
$labelCompany.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelCompany)

#TextBox - "Company"
$textBoxCompany = New-Object System.Windows.Forms.TextBox
$textBoxCompany.Location = New-Object System.Drawing.Point(120, 620)
$textBoxCompany.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxCompany)

#Label - "Location"
$labelLocation = New-Object System.Windows.Forms.Label
$labelLocation.Text = "Location"
$labelLocation.Location = New-Object System.Drawing.Point(10, 650)
$labelLocation.Size = New-Object System.Drawing.Size(100, 20)
$labelLocation.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$form.Controls.Add($labelLocation)

#TextBox - "Location"
$textBoxLocation = New-Object System.Windows.Forms.TextBox
$textBoxLocation.Location = New-Object System.Drawing.Point(120, 650)
$textBoxLocation.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBoxLocation)

#Button - "Save Changes"
$buttonSave = New-Object System.Windows.forms.Button
$buttonSave.Text = "Save Changes"
$buttonSave.Location = New-Object System.Drawing.Point(140, 690)
$buttonSave.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($buttonSave)

<#------------------------------------------------------------------Password/Account Information (GUI)-------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

#Header - "Password/Account Information"
$labelPasAcc = New-Object System.Windows.Forms.Label
$labelPasAcc.Text = "Password / Account Information"
$labelPasAcc.Location = New-Object System.Drawing.Point(370, 180)
$labelPasAcc.Size = New-Object System.Drawing.Size(180, 20)
$labelPasAcc.Font = New-Object System.Drawing.Font($labelUserData.Font, [System.Drawing.FontStyle]::Underline)
$form.Controls.Add($labelPasAcc)

#CheckBox - "Unlock AD Account"
$checkBoxADLock = New-Object System.Windows.Forms.CheckBox
$checkBoxADLock.Location = New-Object System.Drawing.Point(385,200)  
$checkBoxADLock.Text = "Unlock AD Account"
$checkBoxADLock.AutoSize = $true
$checkBoxADLock.Enabled = $false
$form.Controls.Add($checkBoxADLock)

#CheckBox - "User must change password at next logon"
$checkBoxPassHasToBeChanged = New-Object System.Windows.Forms.CheckBox
$checkBoxPassHasToBeChanged.Location = New-Object System.Drawing.Point(385,230)  
$checkBoxPassHasToBeChanged.Text = "User must change password at next logon"
$checkBoxPassHasToBeChanged.AutoSize = $true
$checkBoxPassHasToBeChanged.Enabled = $false
$form.Controls.Add($checkBoxPassHasToBeChanged)

#CheckBox - "Password never expires"
$checkBoxPassNeverExpires = New-Object System.Windows.Forms.CheckBox
$checkBoxPassNeverExpires.Location = New-Object System.Drawing.Point(385,260)  
$checkBoxPassNeverExpires.Text = "Password never expires"
$checkBoxPassNeverExpires.AutoSize = $true
$checkBoxPassNeverExpires.Enabled = $false
$form.Controls.Add($checkBoxPassNeverExpires)

#CheckBox - "Password cannot be changed"
$checkBoxPassCantBeChanged = New-Object System.Windows.Forms.CheckBox
$checkBoxPassCantBeChanged.Location = New-Object System.Drawing.Point(385,290)  
$checkBoxPassCantBeChanged.Text = "Password cannot be changed"
$checkBoxPassCantBeChanged.AutoSize = $true
$checkBoxPassCantBeChanged.Enabled = $false
$form.Controls.Add($checkBoxPassCantBeChanged)

#Label - "Last password change"
$labelLastPassChange = New-Object System.Windows.Forms.Label
$labelLastPassChange.Text = "Last password change"
$labelLastPassChange.Location = New-Object System.Drawing.Point(385, 360)
$labelLastPassChange.Size = New-Object System.Drawing.Size(140, 20)
$form.Controls.Add($labelLastPassChange)

#DateTimePicker - "Last password change"
$dtpLastPassChange = New-Object System.Windows.Forms.DateTimePicker
$dtpLastPassChange.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
$dtpLastPassChange.CustomFormat = "dd.MM.yyyy - HH:mm:ss"  
$dtpLastPassChange.ShowUpDown = $false   
$dtpLastPassChange.Location = New-Object System.Drawing.Point(535, 360)
$dtpLastPassChange.Size = New-Object System.Drawing.Size(200, 20)
$dtpLastPassChange.Enabled = $false  
$form.Controls.Add($dtpLastPassChange)

#Label - "Password expires on"
$labelPassExpiresAt = New-Object System.Windows.Forms.Label
$labelPassExpiresAt.Text = "Password expires on"
$labelPassExpiresAt.Location = New-Object System.Drawing.Point(385, 390)
$labelPassExpiresAt.Size = New-Object System.Drawing.Size(130, 20)
$form.Controls.Add($labelPassExpiresAt)

#DateTimePicker - "Password expires on"
$dtpPassExpiresAt = New-Object System.Windows.Forms.DateTimePicker
$dtpPassExpiresAt.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
$dtpPassExpiresAt.CustomFormat = "dd.MM.yyyy - HH:mm:ss" 
$dtpPassExpiresAt.ShowUpDown = $false   
$dtpPassExpiresAt.Location = New-Object System.Drawing.Point(535, 390)
$dtpPassExpiresAt.Size = New-Object System.Drawing.Size(200, 20)
$dtpPassExpiresAt.Enabled = $false  
$form.Controls.Add($dtpPassExpiresAt)

#Label - "Last logon"
$labelLastLogin = New-Object System.Windows.Forms.Label
$labelLastLogin.Text = "Last logon"
$labelLastLogin.Location = New-Object System.Drawing.Point(385, 330)
$labelLastLogin.Size = New-Object System.Drawing.Size(130, 20)
$form.Controls.Add($labelLastLogin)

#DateTimePicker - "Last logon"
$dtpLastLogin = New-Object System.Windows.Forms.DateTimePicker
$dtpLastLogin.Format = [System.Windows.Forms.DateTimePickerFormat]::Custom
$dtpLastLogin.CustomFormat = "dd.MM.yyyy - HH:mm:ss" 
$dtpLastLogin.ShowUpDown = $false   
$dtpLastLogin.Location = New-Object System.Drawing.Point(535, 330)
$dtpLastLogin.Size = New-Object System.Drawing.Size(200, 20)
$dtpLastLogin.Enabled = $false  # Setzt das Feld auf schreibgeschützt
$form.Controls.Add($dtpLastLogin)

#Button - "Save Password Settings"
$buttonUpdatePassSett = New-Object System.Windows.forms.Button
$buttonUpdatePassSett.Text = "Save Password Settings"
$buttonUpdatePassSett.Location = New-Object System.Drawing.Point(460, 430)
$buttonUpdatePassSett.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($buttonUpdatePassSett)

#Label - "Enter temporary password"
$labelInsertNewPass = New-Object System.Windows.Forms.Label
$labelInsertNewPass.Text = "Enter temporary password"
$labelInsertNewPass.Location = New-Object System.Drawing.Point(385, 490)
$labelInsertNewPass.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($labelInsertNewPass)

#Label - "(the user must set their own password upon next login)"
$labelInsertNewPass = New-Object System.Windows.Forms.Label
$labelInsertNewPass.Text = "(the user must set their own password upon next login)"
$labelInsertNewPass.Location = New-Object System.Drawing.Point(385, 510)
$labelInsertNewPass.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($labelInsertNewPass)

#TextBox - "Temporary Password"
$textBoxInsertNewPass = New-Object System.Windows.Forms.TextBox
$textBoxInsertNewPass.Location = New-Object System.Drawing.Point(385, 530)
$textBoxInsertNewPass.Size = New-Object System.Drawing.Size(350, 20)
$textBoxInsertNewPass.ReadOnly = $true
$form.Controls.Add($textBoxInsertNewPass)

#Button - "Set Temporary Password"
$buttonResetPass = New-Object System.Windows.forms.Button
$buttonResetPass.Text = "Set Temporary Password"
$buttonResetPass.Location = New-Object System.Drawing.Point(470, 570)
$buttonResetPass.Size = New-Object System.Drawing.Size(170, 20)
$form.Controls.Add($buttonResetPass)

<#---------------------------------------------------------------------User Search (Functions)---------------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

$ouDN = "OU=Path,DC=to,DC=your,DC=OU"

#Button - "Search"
$buttonSearch.Add_Click({
    $dataGridView.Rows.Clear()

    $searchValue = $textBoxSearch.Text

    #Search user account in AD
    $users = Get-ADUser -Filter {GivenName -like $searchValue -or Surname -like $searchValue -or SamAccountName -like $searchValue} -SearchBase $ouDN -Properties *
    
    if ($users.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No users could be found that match your input.`n`nPlease make sure that the name is entered correctly.", 
        "AD User Information Center", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        #Display found users in DataGridView
        foreach ($user in $users) {
            $rowIndex = $dataGridView.Rows.Add()
            $dataGridView.Rows[$rowIndex].Cells[0].Value = $user.GivenName
            $dataGridView.Rows[$rowIndex].Cells[1].Value = $user.Surname
            $dataGridView.Rows[$rowIndex].Cells[2].Value = $user.SamAccountName
        }
    }  

    #Disable checkboxes which are in conflict with other checkboxes  
    $checkBoxPassHasToBeChanged.add_CheckedChanged({
        if($checkBoxPassHasToBeChanged.Checked -eq $true){
            $checkBoxPassCantBeChanged.Enabled = $false
        } else {
            $checkBoxPassCantBeChanged.Enabled = $true
        }
    })
    
    $checkBoxPassCantBeChanged.add_CheckedChanged({
        if($checkBoxPassCantBeChanged.Checked -eq $true){
            $checkBoxPassHasToBeChanged.Enabled = $false
        } else {
            $checkBoxPassHasToBeChanged.Enabled = $true
        }
    })
    
    $checkBoxPassNeverExpires.add_CheckedChanged({
        if($checkBoxPassNeverExpires.Checked -eq $true){
            $checkBoxPassExpired.Enabled = $false
        } else {
            $checkBoxPassExpired.Enabled = $true
        }
    })
})

$dataGridView.add_SelectionChanged({
    if ($dataGridView.SelectedRows.Count -gt 0) {

        #User was selected, activate checkboxes
        $checkBoxADLock.Enabled = $true
        $checkBoxPassHasToBeChanged.Enabled = $true
        $checkBoxPassNeverExpires.Enabled = $true
        $checkBoxPassCantBeChanged.Enabled = $true
        $textBoxInsertNewPass.ReadOnly = $false

        $selectedUserName = $dataGridView.SelectedRows[0].Cells[2].Value

        #Search selected user in AD
        $selectedUser = Get-ADUser -Filter { SamAccountName -eq $selectedUserName } -Properties *

        #Fill the textboxes with user information
        $textBoxSurname.Text = $selectedUser.Surname
        $textBoxFirstName.Text = $selectedUser.GivenName
        $textBoxUserName.Text = $selectedUser.SamAccountName
        $textBoxDescription.Text = $selectedUser.Description
        $textBoxEMail.Text = $selectedUser.EmailAddress
        $textBoxPhone.Text = $selectedUser.telephoneNumber
        $textBoxPhone2.Text = $selectedUser.otherTelephone
        $textBoxMobile.Text = $selectedUser.mobile
        $textBoxPosition.Text = $selectedUser.Title
        $textBoxDepartment.Text = $selectedUser.Department
        $textBoxCompany.Text = $selectedUser.Company
        $textBoxSAP.Text = $selectedUser.<yourADAttribute>
        $textBoxEmployeeID.Text = $selectedUser.employeeID
        $textBoxSalute.Text = $selectedUser.<yourADAttribute>
        $textBoxLocation.Text = $selectedUser.location
        $textBoxHOME.Text = $selectedUser.homeDrive + $selectedUser.homeDirectory
    } 
})

#Button - "Clear Entry"
$buttonClear.Add_Click({
    $textBoxSearch.Clear()
    $dataGridView.Rows.Clear()
    $textBoxSurname.Clear()
    $textBoxFirstName.Clear()
    $textBoxUserName.Clear()
    $textBoxDescription.Clear()
    $textBoxEMail.Clear()
    $textBoxPhone.Clear()
    $textBoxPhone2.Clear()
    $textBoxMobile.Clear()
    $textBoxSalute.Clear()
    $textBoxSAP.Clear()
    $textBoxEmployeeID.Clear()
    $textBoxPosition.Clear()
    $textBoxDepartment.Clear()
    $textBoxCompany.Clear()
    $textBoxLocation.Clear()
    $textBoxOU.Clear()
    $textBoxHOME.Clear()

    #Lock checkboxes
    $checkBoxADLock.Enabled = $false
    $checkBoxPassHasToBeChanged.Enabled = $false
    $checkBoxPassNeverExpires.Enabled = $false
    $checkBoxPassCantBeChanged.Enabled = $false
})

#Display OU 
$dataGridView.add_SelectionChanged({
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedUserName = $dataGridView.SelectedRows[0].Cells[2].Value

        #Search selected user in AD
        $selectedUser = Get-ADUser -Filter { SamAccountName -eq $selectedUserName } -Properties DistinguishedName

        #Enter the OU path into the textbox
        $textBoxOU.Text = $selectedUser.DistinguishedName
    }
})

<#---------------------------------------------------------------------User Information (Functions)------------------------------------------------------------------------#>
<#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

#Button - "Save Changes"
$buttonSave.Add_Click({
    try{
        #Get information from the textboxes
        $surname = $textBoxSurname.Text
        $firstName = $textBoxFirstName.Text
        $description = $textBoxDescription.Text
        $phone = $textBoxPhone.Text
        $phone2 = $textBoxPhone2.Text
        $mobile = $textBoxMobile.Text
        $title = $textBoxPosition.Text
        $department = $textBoxDepartment.Text
        $company = $textBoxCompany.Text
        $salute = $textBoxSalute.Text
        $location = $textBoxLocation.Text
    
        #Save SamAccountName in a string 
        $selectedUserName = $dataGridView.SelectedRows[0].Cells[2].Value

        #Hash table for the values to be replaced
        $replaceProperties = @{}

        #Only consider filled textboxes
        if ($surname) { $replaceProperties["sn"] = $surname } 
        if ($firstName) { $replaceProperties["givenName"] = $firstName } 
        if ($description) { $replaceProperties["description"] = $description } 
        if ($title) { $replaceProperties["title"] = $title } 
        if ($department) { $replaceProperties["department"] = $department }
        if ($company) { $replaceProperties["company"] = $company } 
        if ($phone) { $replaceProperties["telephoneNumber"] = $phone } 
        if ($phone2) { $replaceProperties["otherTelephone"] = $phone2 } 
        if ($mobile) { $replaceProperties["mobile"] = $mobile } 
        if ($location) { $replaceProperties["location"] = $location } 
        if ($salute) { $replaceProperties["<yourADAttribute>"] = $salute } 

        #Save all changes
        if ($replaceProperties.Count -gt 0) {
            Set-ADUser -Identity $selectedUserName -Replace $replaceProperties
            [System.Windows.MessageBox]::Show("All changes have been saved.", "AD User Information Center", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    } catch {
        #Message if an error occurs
        $errorMessage = $_.Exception.Message
        [System.Windows.MessageBox]::Show("An error occurred while updating the user information:`n`n$errorMessage", 
        "AD User Information Center", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

<#-----------------------------------------------------------Passwort / Account Information (Functions)------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

$dataGridView.add_SelectionChanged({
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedUserName = $dataGridView.SelectedRows[0].Cells[2].Value
        $selectedUser = Get-ADUser -Filter { SamAccountName -eq $selectedUserName } -Properties *

        #Last logon
        if ($selectedUser.LastLogonDate) {
            $dtpLastLogin.Value = [DateTime]::Parse($selectedUser.LastLogonDate.ToString())
        } else {
            #January 1st of the current year as the default value
            $dtpLastLogin.Value = [DateTime]::Now.Date.AddDays(-([DateTime]::Now.DayOfYear - 1))
        }
        
        #Last password change
        if ($selectedUser.PasswordLastSet) {
            $dtpLastPassChange.Value = [DateTime]::Parse($selectedUser.PasswordLastSet.ToString())
        } else {
            $dtpLastPassChange.Value = [DateTime]::Now.Date.AddDays(-([DateTime]::Now.DayOfYear - 1))
        }

        #Expiration date = Last password change + 90 days
        if ($selectedUser.PasswordLastSet) {
            $passwordLastSetDate = [DateTime]::Parse($selectedUser.PasswordLastSet.ToString())
            $expiryDate = $passwordLastSetDate.AddDays(90)
            $dtpPassExpiresAt.Value = $expiryDate
        } else {
            $dtpPassExpiresAt.Value = [DateTime]::Now.Date.AddDays(-([DateTime]::Now.DayOfYear - 1))
        }
    }
})

#Button - "Save Password Settings"
$buttonUpdatePassSett.Add_Click({
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedUserName = $dataGridView.SelectedRows[0].Cells[2].Value
        try{
            if($checkBoxADLock.Checked -eq $true){
                Set-ADUser -Identity $selectedUserName -Enabled $true
            }
        
            if($checkBoxPassHasToBeChanged.Checked -eq $true){
                Set-ADUser -Identity $selectedUserName -ChangePasswordAtLogon $true
            } else {
                Set-ADUser -Identity $selectedUserName -ChangePasswordAtLogon $false
            }

            if($checkBoxPassNeverExpires.Checked -eq $true){
                Set-ADUser -Identity $selectedUserName -PasswordNeverExpires $true
            } else {
                Set-ADUser -Identity $selectedUserName -PasswordNeverExpires $false
            }

            if($checkBoxPassCantBeChanged.Checked -eq $true){
                Set-ADUser -Identity $selectedUserName -CannotChangePassword $true
            } else {
                Set-ADUser -Identity $selectedUserName -CannotChangePassword $false
            }

            [System.Windows.MessageBox]::Show("The account settings have been successfully applied.", "AD User Information Center", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            $errorMessage = $_.Exception.Message
            [System.Windows.MessageBox]::Show("An error occurred while updating the account settings:`n`n$errorMessage", "AD User Information Center", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
})

#Button - "Set Temporary Password" 
$buttonResetPass.Add_Click({
    $newPassword = $textBoxInsertNewPass.Text
    $selectedUserName = $dataGridView.SelectedRows[0].Cells[2].Value
        try{
            Set-ADAccountPassword -Identity $selectedUserName -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force) -Reset
            Set-ADUser -Identity $selectedUserName -ChangePasswordAtLogon $True
            [System.Windows.MessageBox]::Show("The password has been successfully set.", "AD User Information Center", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            $textBoxInsertNewPass.Clear()
        } catch{
            $errorMessage = $_.Exception.Message
            [System.Windows.MessageBox]::Show("An error occurred while setting the password:`n`n$errorMessage", "AD User Information Center", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
})

$form.ShowDialog() | Out-Null
