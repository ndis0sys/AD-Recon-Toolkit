<#
.SYNOPSIS
    Выводит пользователей AD, которые долго не логинились или не меняли пароль.
.DESCRIPTION
    Скрипт проверяет учётки пользователей AD и выводит те, у которых:
    - Enabled = True
    - LastLogonTimeStamp старше указанного количества дней
    - PasswordLastSet старше указанного количества дней

    Позволяет быстро находить “забытые” или потенциально опасные учётки.
    Результаты экспортируются в CSV.
#>

Import-Module ActiveDirectory

# Параметры
$Days = 365
$SearchDate = (Get-Date).AddDays(-$Days)

# AD база поиска (можно оставить корень домена, либо указать OU)
$SearchBase = "DC=childdomain,DC=parentdomain,DC=co,DC=za"

# Получаем пользователей с LastLogonTimeStamp старше $Days
$DormantLogons = Get-ADUser -Filter {(Enabled -eq $True) -and (LastLogonTimeStamp -lt $SearchDate)} `
    -Properties LastLogonDate, Enabled, SamAccountName, pwdLastSet -SearchBase $SearchBase |
    Select Name, LastLogonDate, Enabled, SamAccountName,
        @{Name="PasswordLastSet";Expression={if ($_.pwdLastSet -ne 0) {[datetime]::FromFileTimeUTC($_.pwdLastSet)} else { $null }}}

# Фильтруем учётки с давно не менявшимся паролем
$NotableAccounts = $DormantLogons | Where-Object { $_.PasswordLastSet -lt $SearchDate -and $_.PasswordLastSet -ne $null }

# Отчёт по количеству
Write-Host "Dormant accounts found: $($DormantLogons.Count)"
Write-Host "Accounts with stale passwords: $($NotableAccounts.Count)"

# Пример случайной учётки (можно удалить, если не нужен)
if ($NotableAccounts.Count -gt 42) {
    Write-Host "Random notable account: $($NotableAccounts[42].SamAccountName)"
}

# Сохраняем результаты в CSV в папку Documents пользователя
$OutputFile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "Inactive_ADuserAccounts.csv"
$NotableAccounts | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Report generated successfully at $OutputFile"
