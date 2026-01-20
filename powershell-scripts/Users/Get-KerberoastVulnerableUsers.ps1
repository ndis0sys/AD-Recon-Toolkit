<#
.SYNOPSIS
    Находит AD-учётки, у которых настроен SPN (ServicePrincipalName) — потенциально уязвимые к Kerberoasting.
.DESCRIPTION
    Скрипт получает все учётки AD с заполненным ServicePrincipalName и выводит следующую информацию:
    - Name
    - Description
    - LastLogon
    - PasswordNeverExpires
    - PasswordLastSet
    - SamAccountName
    Результаты экспортируются в CSV в папку Documents пользователя.
#>

Import-Module ActiveDirectory

# Путь для CSV (Documents пользователя)
$DocsPath = [Environment]::GetFolderPath('MyDocuments')
$OutputFile = Join-Path $DocsPath "KerberoastVulnerableAccounts.csv"

# Получение учёток с SPN
$KerberoastUsers = Get-ADUser -Filter {ServicePrincipalName -ne $null} `
    -Properties ServicePrincipalName, Description, LastLogonDate, PasswordNeverExpires, PasswordLastSet, SamAccountName

# Выбор полей и экспорт
$KerberoastUsers | Select-Object `
    Name,
    Description,
    @{Name="LastLogon";Expression={[datetime]::FromFileTime($_.LastLogonDate)}},
    PasswordNeverExpires,
    @{Name="PasswordLastSet";Expression={$_.PasswordLastSet}},
    SamAccountName | Export-Csv -Path $OutputFile -NoTypeInformation

Write-Host "Export completed. The file is saved at: $OutputFile"
