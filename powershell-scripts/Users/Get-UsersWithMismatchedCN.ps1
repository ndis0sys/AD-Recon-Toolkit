<#
.SYNOPSIS
Идентифицирует пользователей Active Directory, у которых CN (RDN) не совпадает с SamAccountName.

.DESCRIPTION
Этот скрипт перечисляет учетные записи пользователей в Active Directory и обнаруживает случаи,
когда общее имя (CN) в отличительном имени отличается от SamAccountName пользователя.

Такие несоответствия могут указывать на проблемы с устаревшей системой именования, ручное 
создание объектов или плохую гигиену Active Directory. Скрипт доступен только для чтения и 
НЕ изменяет никакие объекты.

#>

Import-Module ActiveDirectory

try {
    $Users = Get-ADUser -Filter * -Properties SamAccountName, DistinguishedName |
        Where-Object {
            $_.SamAccountName -and $_.DistinguishedName
        }
}
catch {
    Write-Error "Failed to retrieve AD users: $($_.Exception.Message)"
    return
}

$Results = foreach ($User in $Users) {

    $CurrentCN = ($User.DistinguishedName -split ',')[0] -replace '^CN='

    if ($CurrentCN -ne $User.SamAccountName) {
        [PSCustomObject]@{
            SamAccountName     = $User.SamAccountName
            CurrentCN          = $CurrentCN
            DistinguishedName  = $User.DistinguishedName
            Issue              = "CN does not match SamAccountName"
        }
    }
}

$Results
