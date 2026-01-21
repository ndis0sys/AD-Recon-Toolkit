<#
.SYNOPSIS
Выполняет полный рабочий процесс разведки Active Directory.

.DESCRIPTION
Действует как скрипт оркестрации, который последовательно выполняет
множественные проверки разведки и гигиены AD.
Не осуществляет эксплуатацию уязвимостей и не изменяет объекты AD.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Domain,

    [Parameter(Mandatory)]
    [string]$Server,

    [Parameter()]
    [switch]$SkipACL,

    [Parameter()]
    [switch]$SkipUsers,

    [Parameter()]
    [switch]$SkipGroups,

    [Parameter()]
    [switch]$SkipComputers
)

$Results = [ordered]@{}

Write-Verbose "[*] Starting AD Recon for domain $Domain"

if (-not $SkipUsers) {
    Write-Verbose "[+] Running user-related checks"
    $Results.Users = @{
        EmptyAttributes = Get-UsersWithEmptyAttributes
    }
}

if (-not $SkipGroups) {
    Write-Verbose "[+] Running group-related checks"
    $Results.Groups = @{
        GroupOverview = Get-ADGroup -Filter *
    }
}

if (-not $SkipComputers) {
    Write-Verbose "[+] Running computer-related checks"
    $Results.Computers = @{
        ComputerCount = (Get-ADComputer -Filter *).Count
    }
}

if (-not $SkipACL) {
    Write-Verbose "[+] Running ACL-related checks"
    $Results.ACL = @{
        Delegation = 'Planned'
    }
}

[PSCustomObject]$Results
