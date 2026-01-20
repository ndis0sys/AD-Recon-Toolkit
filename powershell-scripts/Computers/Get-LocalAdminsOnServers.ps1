<#
.SYNOPSIS
    Находит локальных администраторов на серверах AD.
.DESCRIPTION
    Скрипт проверяет все включённые серверы в Active Directory и собирает список 
    пользователей, входящих в локальную группу "Administrators" на каждом сервере.
    Включает информацию:
    - ComputerName
    - Administrator
    Результаты экспортируются в CSV в папку Documents пользователя.
#>

Import-Module ActiveDirectory

# Параметры
$CutoffDate = (Get-Date).AddDays(-8)  # Только серверы с активным LastLogonDate
$Result = @()

# Получаем серверные компьютеры из AD
$ServerList = Get-ADComputer -Filter {
    Enabled -eq $true -and OperatingSystem -like "*Server*"
} -Properties Name, OperatingSystem, LastLogonDate | Where-Object {
    $_.LastLogonDate -ne $null -and $_.LastLogonDate -ge $CutoffDate
}

Write-Host "Total servers found: $($ServerList.Count)"

# Цикл по серверам и сбор локальных админов
foreach ($Server in $ServerList) {
    $ComputerName = $Server.Name
    Write-Host "Checking local admins on: $ComputerName"

    try {
        $Admins = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            try {
                $Group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
                $Members = @()
                $Group.Members() | ForEach-Object {
                    $Members += $_.GetType().InvokeMember("Name",'GetProperty',$null,$_, $null)
                }
                return $Members
            } catch {
                return @("Error: $_")
            }
        } -ErrorAction Stop

        foreach ($Admin in $Admins) {
            $Result += [PSCustomObject]@{
                ComputerName  = $ComputerName
                Administrator = $Admin
            }
        }
    } catch {
        $Result += [PSCustomObject]@{
            ComputerName  = $ComputerName
            Administrator = "Connection Failed: $_"
        }
    }
}

# Сохраняем результаты в CSV в папку Documents
$OutputFile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "Local_Admins_Report.csv"
$Result | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Report saved to $OutputFile"
