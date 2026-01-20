<#
.SYNOPSIS
    Находит объекты AD, на которые текущий пользователь имеет права записи.
.DESCRIPTION
    Скрипт проверяет все объекты в домене Active Directory и выводит те, где текущий пользователь
    имеет права WriteProperty, GenericWrite или GenericAll.
    Включает информацию:
    - ObjectName
    - DistinguishedName
    - RightsGranted
    Результаты экспортируются в CSV в папку Documents пользователя.
#>

Import-Module ActiveDirectory

# Текущий пользователь
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Контекст домена
$Domain = Get-ADDomain
$SearchBase = $Domain.DistinguishedName

Write-Host "Retrieving all objects in the domain..." -ForegroundColor Yellow
$ADObjects = Get-ADObject -Filter * -SearchBase $SearchBase -Properties DistinguishedName

$Results = @()

Write-Host "Checking permissions on objects..." -ForegroundColor Yellow

foreach ($Obj in $ADObjects) {
    try {
        $ACL = Get-Acl "AD:$($Obj.DistinguishedName)" -ErrorAction SilentlyContinue
        
        $UserPermissions = $ACL.Access | Where-Object {
            $_.IdentityReference -like "*$CurrentUser" -and ($_.ActiveDirectoryRights -match "WriteProperty|GenericWrite|GenericAll")
        }

        if ($UserPermissions) {
            $Results += [PSCustomObject]@{
                ObjectName        = $Obj.Name
                DistinguishedName = $Obj.DistinguishedName
                RightsGranted     = ($UserPermissions | ForEach-Object { $_.ActiveDirectoryRights }) -join ", "
            }
        }
    } catch {
        Write-Warning "Failed to retrieve ACL for object: $($Obj.DistinguishedName)"
    }
}

# Экспорт в CSV в папку Documents
$OutputFile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "ADObjectsWithUserWritePermissions.csv"
$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

# Вывод результата в консоль
if ($Results.Count -gt 0) {
    Write-Host "Objects with permissions found: $($Results.Count)" -ForegroundColor Green
} else {
    Write-Host "No objects found where you have write, modify, or full access permissions." -ForegroundColor Red
}

Write-Host "Report generated successfully at $OutputFile"
