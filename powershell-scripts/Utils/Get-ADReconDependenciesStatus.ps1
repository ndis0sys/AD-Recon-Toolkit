<#
.SYNOPSIS
Проверяет наличие необходимых инструментов и настроек среды для разведки Active Directory.

.DESCRIPTION
Проверяет наличие распространенных зависимостей для разведки AD, таких как PowerView, SharpHound,
PowerMad, GPRegistryPolicy, Impacket, CrackMapExec и Python.

Также проверяет настройки усиления безопасности домена, включая усиленные UNC-пути SYSVOL и NETLOGON.
#>

[CmdletBinding()]
param ()

$Results = @()

function Test-Dependency {
    param (
        [string]$Name,
        [string]$Path,
        [string]$Command
    )

    $Exists = Test-Path -Path $Path
    $CommandAvailable = $true

    if ($Command) {
        $CommandAvailable = [bool](Get-Command $Command -ErrorAction SilentlyContinue)
    }

    [PSCustomObject]@{
        Component        = $Name
        Path             = $Path
        PathExists       = $Exists
        CommandAvailable = $CommandAvailable
        Status           = if ($Exists -and $CommandAvailable) { 'OK' } else { 'Missing' }
    }
}

# Dependency paths
$Dependencies = @(
    @{ Name = 'PowerView';        Path = "$PSScriptRoot\import\PowerView.ps1";                          Command = 'Get-DomainUser' }
    @{ Name = 'SharpHound';       Path = "$PSScriptRoot\import\Sharphound.ps1";                         Command = 'Invoke-BloodHound' }
    @{ Name = 'PowerMad';         Path = "$PSScriptRoot\import\Powermad.ps1";                           Command = 'Get-ADIDNSPermission' }
    @{ Name = 'GPRegistryPolicy'; Path = "$PSScriptRoot\import\GPRegistryPolicy\GPRegistryPolicy.psd1"; Command = 'Parse-PolFile' }
    @{ Name = 'PortScan';         Path = "$PSScriptRoot\import\Invoke-Portscan.ps1";                   Command = 'Invoke-Portscan' }
    @{ Name = 'Impacket';         Path = "$PSScriptRoot\import\impacket\examples\GetUserSPNs.py";       Command = $null }
    @{ Name = 'CrackMapExec';     Path = "$PSScriptRoot\import\cme";                                   Command = $null }
    @{ Name = 'LdapRelayScan';    Path = "$PSScriptRoot\import\LdapRelayScan\LdapRelayScan.py";         Command = $null }
)

foreach ($Dep in $Dependencies) {
    $Results += Test-Dependency @Dep
}

# Python check
$PythonAvailable = $false
try {
    $PythonAvailable = (python -V 2>$null) -match 'Python'
} catch {}

$Results += [PSCustomObject]@{
    Component        = 'Python'
    Path             = 'System PATH'
    PathExists       = $PythonAvailable
    CommandAvailable = $PythonAvailable
    Status           = if ($PythonAvailable) { 'OK' } else { 'Missing' }
}

# Hardened UNC paths check
try {
    $HardenedPaths = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths'
} catch {
    $HardenedPaths = $null
}

$Results += [PSCustomObject]@{
    Component        = 'SYSVOL Hardened UNC'
    Path             = '\\*\SYSVOL'
    PathExists       = $HardenedPaths -and ($HardenedPaths.PSObject.Properties.Name -contains '\\*\SYSVOL')
    CommandAvailable = $true
    Status           = if ($HardenedPaths -and ($HardenedPaths.PSObject.Properties.Name -contains '\\*\SYSVOL')) { 'OK' } else { 'Missing' }
}

$Results += [PSCustomObject]@{
    Component        = 'NETLOGON Hardened UNC'
    Path             = '\\*\NETLOGON'
    PathExists       = $HardenedPaths -and ($HardenedPaths.PSObject.Properties.Name -contains '\\*\NETLOGON')
    CommandAvailable = $true
    Status           = if ($HardenedPaths -and ($HardenedPaths.PSObject.Properties.Name -contains '\\*\NETLOGON')) { 'OK' } else { 'Missing' }
}

return $Results
