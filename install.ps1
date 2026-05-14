$ErrorActionPreference = "Stop"

$installDir = Join-Path $env:LOCALAPPDATA "LocalLM"
$zipPath = Join-Path $env:TEMP "LocalLM-windows-x64.zip"
$downloadUrl = "https://github.com/marioportillohernaiz/LocalLM/releases/latest/download/LocalLM-windows-x64.zip"

Write-Host "Downloading LocalLM..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "Installing LocalLM..."
Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $installDir | Out-Null
Expand-Archive $zipPath -DestinationPath $installDir -Force

Write-Host "Starting LocalLM..."
$startScript = Join-Path $installDir "LocalLM\start-locallm.ps1"
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$startScript`""

Write-Host "LocalLM installed at $installDir"
