<#
.SYNOPSIS
    Находит устаревшие (legacy) и неактивные учётки пользователей AD.
.DESCRIPTION
    Скрипт проверяет всех пользователей Active Directory и выявляет:
    1. Legacy accounts – учётки старше 2 лет с PasswordNeverExpires = True и последним изменением пароля > 1 года назад.
    2. Inactive accounts – учётки, которые не логинились последние 6 месяцев или никогда не логинились.
    Включает информацию:
    - UserName, DisplayName
    - WhenCreated, PasswordLastSet, PasswordNeverExpires, LastLogon, Enabled
    Результаты экспортируются в CSV в папку Documents пользователя.
#>

Import-Module ActiveDirectory

# Временные рамки
$TwoYearsAgo = (Get-Date).AddYears(-2)
$OneYearAgo = (Get-Date).AddYears(-1)
$SixMonthsAgo = (Get-Date).AddMonths(-6)

# Папка для вывода CSV
$DocsPath = [Environment]::GetFolderPath('MyDocuments')
$LegacyAccountsFile = Join-Path $DocsPath "LegacyAccounts_Report.csv"
$InactiveAccountsFile = Join-Path $DocsPath "InactiveAccounts_Report.csv"

$LegacyAccountsResults = @()
$InactiveAccountsResults = @()

# Legacy accounts
Write-Host "Identifying legacy accounts..." -ForegroundColor Yellow
$LegacyAccounts = Get-ADUser -Filter * -Property WhenCreated, PasswordLastSet, PasswordNeverExpires, Enabled | Where-Object {
    $_.WhenCreated -lt $TwoYearsAgo -and
    $_.PasswordLastSet -lt $OneYearAgo -and
    $_.PasswordNeverExpires -eq $true
}

foreach ($Account in $LegacyAccounts) {
    $LegacyAccountsResults += [PSCustomObject]@{
        UserName             = $Account.SamAccountName
        DisplayName          = $Account.Name
        WhenCreated          = $Account.WhenCreated
        PasswordLastSet      = $Account.PasswordLastSet
        PasswordNeverExpires = $Account.PasswordNeverExpires
        Enabled              = $Account.Enabled
    }
}

# Inactive accounts
Write-Host "Identifying inactive accounts..." -ForegroundColor Yellow
$InactiveAccounts = Get-ADUser -Filter * -Property LastLogonDate, Enabled | Where-Object {
    $_.LastLogonDate -lt $SixMonthsAgo -or $_.LastLogonDate -eq $null
}

foreach ($InactiveAccount in $InactiveAccounts) {
    $InactiveAccountsResults += [PSCustomObject]@{
        UserName    = $InactiveAccount.SamAccountName
        DisplayName = $InactiveAccount.Name
        LastLogon   = $InactiveAccount.LastLogonDate
        Enabled     = $InactiveAccount.Enabled
        Status      = "Inactive"
    }
}

# Экспорт в CSV
$LegacyAccountsResults | Export-Csv -Path $LegacyAccountsFile -NoTypeInformation -Encoding UTF8
$InactiveAccountsResults | Export-Csv -Path $InactiveAccountsFile -NoTypeInformation -Encoding UTF8

Write-Host "Reports generated successfully:"
Write-Host "Legacy Accounts Report: $LegacyAccountsFile"
Write-Host "Inactive Accounts Repor
