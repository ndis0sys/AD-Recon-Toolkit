<#
.SYNOPSIS
Создает матрицу членства пользователей в группах Active Directory.

.DESCRIPTION
Этот скрипт собирает группы Active Directory на основе фильтра,
рекурсивно перечисляет их пользователей-членов и создает CSV-отчет,
где каждая строка представляет пользователя, а каждый столбец — группу.

Полезно для:
- аудита членства в группах
- выявления чрезмерного или неожиданного доступа
- экспорта данных для анализа в Excel
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [string]$GroupFilter = 'GroupCategory -eq "Distribution"'
)

Import-Module ActiveDirectory

Write-Verbose "Retrieving AD groups using filter: $GroupFilter"
$Groups = Get-ADGroup -Filter $GroupFilter
$Users = @{}

foreach ($Group in $Groups) {
    Write-Verbose "Processing group: $($Group.Name)"
    $Members = Get-ADGroupMember $Group -Recursive

    foreach ($Member in $Members) {
        if ($Member.objectClass -ne 'user') {
            continue
        }

        if (-not $Users.ContainsKey($Member.SamAccountName)) {
            $Users[$Member.SamAccountName] = @{}
        }

        $Users[$Member.SamAccountName][$Group.Name] = $true
    }
}

$Results = @()

foreach ($UserEntry in $Users.GetEnumerator()) {
    $ADUser = Get-ADUser -Identity $UserEntry.Key -Properties `
        physicalDeliveryOfficeName,
        Office,
        Department,
        Company,
        City,
        telephoneNumber,
        Enabled,
        UserPrincipalName

    $UserObject = [PSCustomObject]@{
        SamAccountName = $UserEntry.Key
        FullName      = $ADUser.Name
        Email         = $ADUser.UserPrincipalName
        Phone         = $ADUser.telephoneNumber
        Department    = $ADUser.Department
        Company       = $ADUser.Company
        City          = $ADUser.City
        Enabled       = $ADUser.Enabled
    }

    foreach ($Group in $Groups) {
        $UserObject | Add-Member -MemberType NoteProperty -Name $Group.Name -Value ''
        if ($UserEntry.Value.ContainsKey($Group.Name)) {
            $UserObject.$($Group.Name) = 'x'
        }
    }

    $Results += $UserObject
}

$Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
