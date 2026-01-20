<#
.SYNOPSIS
    Находит пользователей AD, у которых не требуется пароль.
.DESCRIPTION
    Скрипт проверяет все включённые учётки пользователей Active Directory и 
    выводит те, у которых установлен атрибут PasswordNotRequired = True.
    Включает информацию:
    - SamAccountName, Name, GivenName
    - Description
    - LastLogonDate, LastLogon, LastLogonTimestamp
    - PasswordLastSet, PasswordNeverExpires
    Результаты экспортируются в CSV в папку Documents пользователя.
#>

Import-Module ActiveDirectory

# Получаем пользователей, которым не требуется пароль
$Users_NoPasswordRequired = Get-ADUser -Filter { PasswordNotRequired -eq $true } `
    -Properties Name, Description, SamAccountName, GivenName, Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, LastLogon, LastLogonTimestamp, PasswordNotRequired |
    Where-Object { $_.Enabled -eq $true }

Write-Host "Total accounts found: $($Users_NoPasswordRequired.Count)"

# Формируем объект с информацией
$UserDetails = $Users_NoPasswordRequired | ForEach-Object {
    # Конвертация LastLogon и LastLogonTimestamp
    $LastLogonReadable = if ($_.LastLogon -gt 0) { [datetime]::FromFileTime($_.LastLogon) } else { $null }
    $LastLogonTimestampReadable = if ($_.LastLogonTimestamp -gt 0) { [datetime]::FromFileTime($_.LastLogonTimestamp) } else { $null }

    [PSCustomObject]@{
        SamAccountName       = $_.SamAccountName
        Name                 = $_.Name
        Description          = $_.Description
        GivenName            = $_.GivenName
        Enabled              = $_.Enabled
        LastLogonDate        = $_.LastLogonDate
        PasswordLastSet      = $_.PasswordLastSet
        PasswordNeverExpires = $_.PasswordNeverExpires
        LastLogon            = $LastLogonReadable
        LastLogonTimestamp   = $LastLogonTimestampReadable
        PasswordNotRequired  = $_.PasswordNotRequired
    }
}

# Сохраняем CSV в папку Documents
$OutputFile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "Users_do_not_require_Passwords.csv"
$UserDetails | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Report generated successfully at $OutputFile"
