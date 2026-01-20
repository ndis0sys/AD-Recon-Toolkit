<#
.SYNOPSIS
    Находит отключённые RDP-сессии на удалённых серверах.
.DESCRIPTION
    Скрипт проверяет список серверов и собирает информацию о RDP-сессиях со статусом "Disc" (отключено).
    Включает следующие данные:
    - ServerName
    - LogonAccount
    - SessionStatus
    - IdleTimeOrDisconnectedTime
    Результаты экспортируются в CSV в папку Documents пользователя.
#>

# Путь к списку серверов (можно редактировать)
$ServersFile = "C:\Servers.txt"

# Папка для вывода CSV
$DocsPath = [Environment]::GetFolderPath('MyDocuments')
$OutputFile = Join-Path $DocsPath "DisconnectedRDPSessions_Report.csv"

# Проверка существования файла серверов
if (-not (Test-Path $ServersFile)) {
    Write-Host "Input file $ServersFile not found." -ForegroundColor Red
    exit
}

# Инициализация CSV с заголовком
"ServerName,LogonAccount,SessionStatus,IdleTimeOrDisconnectedTime" | Out-File -FilePath $OutputFile -Encoding UTF8

# Получение списка серверов
$Servers = Get-Content $ServersFile

# Итерация по каждому серверу
foreach ($Server in $Servers) {
    Write-Host "Checking server: $Server"

    try {
        # Получаем сессии через qwinsta
        $Sessions = qwinsta /server:$Server | ForEach-Object {
            ($_.Trim() -replace '\s{2,}', ',').Split(',')
        } | Where-Object { $_[0] -match '^[0-9]+$' -and $_[3] -eq 'Disc' }

        # Обработка каждой отключённой сессии
        foreach ($Session in $Sessions) {
            $LogonAccount = $Session[1]
            $Status = $Session[3]
            $IdleTime = $Session[4]

            # Добавление строки в CSV
            "$Server,$LogonAccount,$Status,$IdleTime" | Out-File -FilePath $OutputFile -Append -Encoding UTF8
        }
    } catch {
        Write-Host "Failed to query $Server" -ForegroundColor Yellow
    }
}

Write-Host "Report generated at $OutputFile" -ForegroundColor Green
