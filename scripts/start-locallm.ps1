$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendExe = Join-Path $root "backend\locallm-backend.exe"
$appExe = Join-Path $root "locallm.exe"

if (-not (Test-Path $backendExe)) {
    throw "Backend executable not found: $backendExe"
}

if (-not (Test-Path $appExe)) {
    throw "LocalLM executable not found: $appExe"
}

Start-Process $backendExe -WindowStyle Hidden
Start-Sleep -Seconds 2
Start-Process $appExe
