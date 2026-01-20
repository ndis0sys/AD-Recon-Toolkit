<#
.SYNOPSIS
    Находит пользователей AD, у которых пароль давно не менялся.
.DESCRIPTION
    Скрипт проверяет всех включённых пользователей AD и выводит тех, чей пароль 
    не менялся с указанной даты. Включает информацию:
    - LastLogon, LastLogonTimeStamp
    - DaysSinceLastLogon
    - Дата создания учётки
    - SamAccountName
    Результаты экспортируются в CSV для удобного анализа.
#>

Import-Module ActiveDirectory

$VerbosePreference = "Continue"

# Дата, с которой проверяем изменение пароля
$SearchDate = "2023-01-01" # yyyy-MM-dd
$SearchBase = "DC=ho,DC=domain,DC=com"

$PasswordsNotChangedSince = ($([datetime]::ParseExact($SearchDate,'yyyy-MM-dd',$null))).ToFileTime()
Write-Verbose "Finding users whose passwords have not changed since $([datetime]::FromFileTimeUTC($PasswordsNotChangedSince))"

# Получаем пользователей
$AccountsNoPasswordChangeSinceDate = Get-ADUser -Filter { Enabled -eq $True } `
    -Properties Name, WhenCreated, SamAccountName, pwdLastSet, LastLogon, LastLogonTimeStamp `
    -SearchBase $SearchBase |
    Where-Object { $_.pwdLastSet -lt $PasswordsNotChangedSince -and $_.pwdLastSet -ne 0 } |
    Select-Object Name, WhenCreated, SamAccountName, `
        @{Name="PasswordLastSet";Expression={[datetime]::FromFileTimeUTC($_.pwdLastSet)}}, `
        @{Name="LastLogon";Expression={if ($_.LastLogon) {[datetime]::FromFileTime($_.LastLogon)} else {$null}}}, `
        @{Name="LastLogonTimeStamp";Expression={if ($_.LastLogonTimeStamp) {[datetime]::FromFileTime($_.LastLogonTimeStamp)} else {$null}}}, `
        @{Name="DaysSinceLastLogon";Expression={ 
            if ($_.LastLogonTimeStamp) { ([timespan]((Get-Date) - ([datetime]::FromFileTime($_.LastLogonTimeStamp)))).Days } else { $null } 
        }}

# Выводим количество учёток
Write-Host "Accounts with stale passwords: $($AccountsNoPasswordChangeSinceDate.Count)"

# Путь сохранения CSV в папку Documents
$OutputFile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "AccountsNoPasswordChangeSinceDate.csv"
$AccountsNoPasswordChangeSinceDate | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Report generated successfully at $OutputFile"
