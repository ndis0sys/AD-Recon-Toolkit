<#
.SYNOPSIS
    Находит пользователей AD с пустыми атрибутами.
.DESCRIPTION
    Этот скрипт извлекает пользователей AD и идентифицирует учетные записи с отсутствующими или пустыми атрибутами (например, описание, номер телефона).
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
    } else {
        $hItemDetails = "FullName: $Item | Not found in AD"
    }

    # Добавляем строку в массив результатов
    $aResults += $hItemDetails
}

# Путь к папке "Документы" текущего пользователя
$DocumentsPath = [Environment]::GetFolderPath("MyDocuments")
$OutputFile = Join-Path $DocumentsPath "Results.txt"

# Сохраняем результаты в текстовый файл
$aResults | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Результаты сохранены в $OutputFile"
