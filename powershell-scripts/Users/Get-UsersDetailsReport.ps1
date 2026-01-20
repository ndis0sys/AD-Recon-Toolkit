<#
.SYNOPSIS
    Собирает детальную информацию по списку пользователей AD.
.DESCRIPTION
    Скрипт берёт список учёток из текстового файла и выводит ключевые атрибуты:
    LastLogon, LastLogonTimestamp, AccountEnabled, PasswordLastSet, PasswordNeverExpires, Description.
    Выгрузка производится в CSV.
.NOTES
    Подходит для AD-Recon, аудита и анализа пользователей.
#>

Import-Module ActiveDirectory

# Входной и выходной файлы
$inputFile = ".\List.txt"  # Список пользователей в твоей папке скриптов
$outputFile = "$([Environment]::GetFolderPath('MyDocuments'))\AD_UserReport.csv"

# Читаем список пользователей
$usernames = Get-Content $inputFile

# Массив для результатов
$outputData = @()

foreach ($username in $usernames) {
    $username = $username.Trim()
    $user = Get-ADUser -Identity $username -Properties LastLogonDate, Enabled, PasswordLastSet, Description, PasswordNeverExpires, LastLogon, LastLogonTimestamp

    if ($user) {
        # Конвертация LastLogon и LastLogonTimestamp
        $lastLogon = if ($user.LastLogon) {[DateTime]::FromFileTime($user.LastLogon)} else { $null }
        $lastLogonTimestamp = if ($user.LastLogonTimestamp) {[DateTime]::FromFileTime($user.LastLogonTimestamp)} else { $null }

        # Собираем объект
        $userInfo = [pscustomobject]@{
            Username             = $user.SamAccountName
            LastLogon            = $lastLogon
            LastLogonTimestamp   = $lastLogonTimestamp
            AccountEnabled       = $user.Enabled
            PasswordLastSet      = $user.PasswordLastSet
            PasswordNeverExpires = $user.PasswordNeverExpires
            Description          = $user.Description
        }

        $outputData += $userInfo
    } else {
        # Если учётка не найдена
        $outputData += [pscustomobject]@{
            Username             = $username
            LastLogon            = "Not found"
            LastLogonTimestamp   = "Not found"
            AccountEnabled       = "Not found"
            PasswordLastSet      = "Not found"
            PasswordNeverExpires = "Not found"
            Description          = "Not found"
        }
    }
}

# Экспорт в CSV
$outputData | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Report generated successfully at $outputFile"
