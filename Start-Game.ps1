param([switch]$Restart)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $projectRoot "backend/local_llm_config.json"
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Missing backend/local_llm_config.json. Share the complete project folder."
}
$llmConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($llmConfig.apiKey) -or $llmConfig.apiKey -like "replace-*") {
    throw "The local model key is not configured."
}

$python = (Get-Command python -ErrorAction Stop).Source
$godot = $env:GODOT_EXE
if (-not $godot) {
    $godotCommand = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($godotCommand) {
        $godot = $godotCommand.Source
    }
}
if (-not $godot) {
    $wingetPackages = Join-Path $env:LOCALAPPDATA "Microsoft/WinGet/Packages"
    $godotPackage = Get-ChildItem -Path $wingetPackages -Directory -Filter "GodotEngine.GodotEngine_*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($godotPackage) {
        $godot = (Get-ChildItem -Path $godotPackage.FullName -File -Filter "Godot*_win64.exe" | Select-Object -First 1).FullName
    }
}
if (-not $godot -or -not (Test-Path -LiteralPath $godot)) {
    throw "Godot 4.7 was not found. Install it or set GODOT_EXE to its executable path."
}

$port = 8077
$healthUrl = "http://127.0.0.1:$port/api/v1/health"
$townName = ([string][char]0x804C) + ([string][char]0x573A) + ([string][char]0x5C0F) + ([string][char]0x9547)
$dataDir = Join-Path $env:APPDATA ("Godot/app_userdata/" + $townName)
$database = Join-Path $dataDir "workplace_town_live_v12.db"
$serverScript = Join-Path $projectRoot "backend/api/server.py"
$sessionPath = Join-Path $dataDir "workplace_town_api_session.json"
$queuePath = Join-Path $dataDir "workplace_town_api_queue.json"
$rejectedPath = Join-Path $dataDir "workplace_town_api_rejected.jsonl"
$expectedContentVersion = "v1.2"
$savedSessionId = ""

function Get-LocalApiStateIssue {
    if (Test-Path -LiteralPath $sessionPath) {
        try {
            $session = Get-Content -LiteralPath $sessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            return "invalid-session-file"
        }
        if (-not $session -or $session.contentVersion -ne $expectedContentVersion) {
            return "content-version-mismatch"
        }
        if ($session.confirmed -and [string]::IsNullOrWhiteSpace([string]$session.sessionId)) {
            return "invalid-confirmed-session"
        }
    }
    if (Test-Path -LiteralPath $queuePath) {
        try {
            $rawQueue = Get-Content -LiteralPath $queuePath -Raw -Encoding UTF8
            if ($rawQueue.Trim() -ne "[]") {
                $queue = $rawQueue | ConvertFrom-Json
                if ($queue -isnot [array]) {
                    return "invalid-event-queue"
                }
                foreach ($item in $queue) {
                    if (-not $item -or $item.contentVersion -ne $expectedContentVersion) {
                        return "content-version-mismatch"
                    }
                }
            }
        } catch {
            return "invalid-event-queue"
        }
    }
    return ""
}

function Archive-LocalApiState([string]$Reason) {
    $sources = @($sessionPath, $queuePath, $rejectedPath) | Where-Object { Test-Path -LiteralPath $_ }
    if (-not $sources) { return "" }
    $archiveRoot = Join-Path $dataDir "api_recovery"
    $archivePath = Join-Path $archiveRoot ((Get-Date -Format "yyyyMMdd-HHmmss-fff") + "-" + $Reason)
    New-Item -ItemType Directory -Path $archivePath -Force | Out-Null
    $moved = @()
    try {
        foreach ($source in $sources) {
            Move-Item -LiteralPath $source -Destination $archivePath -ErrorAction Stop
            $moved += $source
        }
    } catch {
        foreach ($source in $moved) {
            Move-Item -LiteralPath (Join-Path $archivePath (Split-Path -Leaf $source)) `
                -Destination $source -ErrorAction SilentlyContinue
        }
        throw "Could not archive local API state; original files were preserved. $($_.Exception.Message)"
    }
    return $archivePath
}

$stateIssue = Get-LocalApiStateIssue
if ($stateIssue) {
    $archivePath = Archive-LocalApiState $stateIssue
    Write-Host "Archived incompatible local API state to: $archivePath"
    Write-Host "The game will start a fresh backend session; archived events will not be replayed."
}
if (Test-Path -LiteralPath $sessionPath) {
    $savedSession = Get-Content -LiteralPath $sessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($savedSession.confirmed -and $savedSession.contentVersion -eq $expectedContentVersion) {
        $savedSessionId = [string]$savedSession.sessionId
    }
}

function Test-SavedSession {
    if (-not $savedSessionId) { return "not-required" }
    try {
        $url = "http://127.0.0.1:$port/api/v1/sessions/$savedSessionId"
        $statusCode = [int](Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3).StatusCode
        if ($statusCode -eq 200) { return "available" }
        return "unavailable"
    } catch {
        $response = $_.Exception.Response
        if ($response) {
            try {
                if ([int]$response.StatusCode -eq 404) { return "missing" }
            } catch { }
        }
        return "unreachable"
    }
}

function Stop-OwnBackend {
    $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $listener) { return }
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)"
    if (-not $process -or $process.CommandLine -notlike "*$serverScript*" -or
        $process.CommandLine -notlike "*$database*" -or $process.CommandLine -notlike "*--port $port*") {
        throw "Port $port is occupied by another process; refusing to stop it."
    }
    Stop-Process -Id $process.ProcessId -ErrorAction Stop
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (-not (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)) { return }
        Start-Sleep -Milliseconds 100
    }
    throw "Port $port did not close after stopping the old backend."
}

if ($Restart) {
    $runningGames = Get-CimInstance Win32_Process -Filter "name like 'Godot%'" |
        Where-Object { $_.CommandLine -like "*$projectRoot*" -and $_.CommandLine -like "*Startup.tscn*" }
    $runningGames | ForEach-Object { Stop-Process -Id $_.ProcessId -ErrorAction Stop }
    Stop-OwnBackend
}

$healthy = $false
try {
    $healthy = (Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2).status -eq "ok"
} catch {
    $healthy = $false
}
if ($healthy -and $savedSessionId) {
    $sessionStatus = Test-SavedSession
    if ($sessionStatus -eq "missing") {
        $archivePath = Archive-LocalApiState "missing-server-session"
        $savedSessionId = ""
        Write-Host "The saved backend session no longer exists. Local API state was archived to: $archivePath"
        Write-Host "The game will start a fresh backend session; archived events will not be replayed."
    } elseif ($sessionStatus -ne "available") {
        throw "Could not verify the saved backend session. The session and event queue were left untouched. Check the local backend and retry."
    }
}
if (-not $healthy) {
    if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
        throw "Port $port is occupied by another process."
    }
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    Start-Process -FilePath $python -WorkingDirectory $projectRoot -WindowStyle Hidden -ArgumentList @(
        "`"$serverScript`"", "--db", "`"$database`"", "--port", "$port"
    ) | Out-Null
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        Start-Sleep -Milliseconds 500
        try {
            if ((Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2).status -eq "ok") {
                $healthy = $true
                break
            }
        } catch {
            continue
        }
    }
    if (-not $healthy) {
        throw "The backend did not start. Python 3.10 or newer is required."
    }
}
if ($savedSessionId) {
    $sessionStatus = Test-SavedSession
    if ($sessionStatus -eq "missing") {
        $archivePath = Archive-LocalApiState "missing-server-session"
        $savedSessionId = ""
        Write-Host "The saved backend session no longer exists. Local API state was archived to: $archivePath"
        Write-Host "The game will start a fresh backend session; archived events will not be replayed."
    } elseif ($sessionStatus -ne "available") {
        throw "Could not verify the saved backend session. The session and event queue were left untouched. Check the local backend and retry."
    }
}

$runningGame = Get-CimInstance Win32_Process -Filter "name like 'Godot%'" |
    Where-Object { $_.CommandLine -like "*$projectRoot*" -and $_.CommandLine -like "*Startup.tscn*" } |
    Select-Object -First 1
if ($runningGame) {
    Write-Host "The game and backend are already running."
    exit 0
}
Start-Process -FilePath $godot -WorkingDirectory $projectRoot -ArgumentList @(
    "--path", "`"$projectRoot`"", "--scene", "res://Startup.tscn"
) | Out-Null
Write-Host "Started the game. Backend: $healthUrl"
