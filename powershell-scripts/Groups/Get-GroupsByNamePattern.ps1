<#
.SYNOPSIS
Находит группы Active Directory по шаблону имени.

.DESCRIPTION
Этот скрипт ищет группы Active Directory, имена которых соответствуют
указанному шаблону с подстановочным знаком.

Полезно для идентификации административных, устаревших, подрядных или
ролевых групп, созданных с использованием непоследовательных соглашений 
об именовании.

Пример использования: .\Get-GroupsByNamePattern.ps1 -NamePattern "*Workstation Admins*"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$NamePattern
)

Import-Module ActiveDirectory

try {
    $Groups = Get-ADGroup -Filter "Name -like '$NamePattern'" -Properties Description
}
catch {
    Write-Error "Failed to retrieve AD groups: $($_.Exception.Message)"
    return
}

$Groups | Select-Object `
    Name,
    Description,
    DistinguishedName
