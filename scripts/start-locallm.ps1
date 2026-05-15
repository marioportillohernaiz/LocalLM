$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendExe = Join-Path $root "backend\locallm-backend.exe"
$appExe = Join-Path $root "locallm.exe"
$dataDir = Join-Path $env:LOCALAPPDATA "LocalLM\data"

if (-not (Test-Path $backendExe)) {
    throw "Backend executable not found: $backendExe"
}

if (-not (Test-Path $appExe)) {
    throw "LocalLM executable not found: $appExe"
}

New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
$env:LOCALLM_DATA_DIR = $dataDir

Start-Process $backendExe -WindowStyle Hidden
Start-Sleep -Seconds 2
Start-Process $appExe
