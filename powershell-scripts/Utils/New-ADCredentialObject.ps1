<#
.SYNOPSIS
Создает объект PSCredential для операций с Active Directory.

.DESCRIPTION
Вспомогательная функция, преобразующая пароль в открытом виде в защищенный объект
PSCredential. Предназначена для использования в контролируемых лабораторных условиях, 
автоматизации и внутренних инструментов для разведки AD.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$User,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Password
)

$DomainUser = "$Domain\$User"

Write-Verbose "[*] Creating credential object for $DomainUser"

$SecurePassword = ConvertTo-SecureString `
    -String $Password `
    -AsPlainText `
    -Force

$Credential = New-Object System.Management.Automation.PSCredential (
    $DomainUser,
    $SecurePassword
)

return $Credential
