<#
.SYNOPSIS
Finds Active Directory users with empty attributes.

.DESCRIPTION
This script retrieves AD users and identifies accounts
with missing or empty attributes (e.g. Description, Phone Number).

.NOTES
Author: ndis0sys
Based on publicly available PowerShell AD audit examples.
Read-only. No changes are made to AD.
#>

Import-Module ActiveDirectory

# Результирующий массив
$aResults = @()

# Список пользователей из файла List.txt
$List = Get-Content ".\List.txt"
            
ForEach($Item in $List){
    $Item = $Item.Trim()
    $User = Get-ADUser -Filter {displayName -like $Item -and SamAccountName -notlike "admin-*" -and Enabled -eq $True} -Properties SamAccountName, GivenName, Surname, telephoneNumber, mail

    if ($User) {
        $hItemDetails = "FullName: $Item | UserName: $($User.SamAccountName) | Email: $($User.mail) | Tel: $($User.telephoneNumber)"
        # Добавляем в массив
        $aResults += $hItemDetails
    } else {
        $aResults += "FullName: $Item | Not found in AD"
    }
}

# Путь к папке "Документы" текущего пользователя
$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$OutputFile = Join-Path $DocumentsPath "Results.txt"

# Сохраняем в текстовый файл
$aResults | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Результаты сохранены в $OutputFile"
