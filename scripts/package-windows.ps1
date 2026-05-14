$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$flutterAppDir = Join-Path $repoRoot "app\flutter_windows_app"
$backendDir = Join-Path $repoRoot "backend"
$backendPython = Join-Path $backendDir ".venv\Scripts\python.exe"
$releaseDir = Join-Path $flutterAppDir "build\windows\x64\runner\Release"
$backendExe = Join-Path $backendDir "dist\locallm-backend.exe"
$distDir = Join-Path $repoRoot "dist"
$packageRoot = Join-Path $distDir "LocalLM"
$packageBackendDir = Join-Path $packageRoot "backend"
$zipPath = Join-Path $distDir "LocalLM-windows-x64.zip"

Write-Host "Building Flutter Windows app..."
Push-Location $flutterAppDir
flutter build windows --release
Pop-Location

Write-Host "Building backend executable..."
Push-Location $backendDir
if (Test-Path $backendPython) {
    & $backendPython -m PyInstaller --onefile --name locallm-backend run.py
} else {
    python -m PyInstaller --onefile --name locallm-backend run.py
}
Pop-Location

if (-not (Test-Path $releaseDir)) {
    throw "Flutter release output was not found: $releaseDir"
}

if (-not (Test-Path $backendExe)) {
    throw "Backend executable was not found: $backendExe"
}

Write-Host "Creating package folder..."
Remove-Item $packageRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $packageBackendDir | Out-Null

Copy-Item (Join-Path $releaseDir "*") -Destination $packageRoot -Recurse -Force
Copy-Item $backendExe -Destination $packageBackendDir -Force
Copy-Item (Join-Path $repoRoot "scripts\start-locallm.ps1") -Destination $packageRoot -Force

Write-Host "Creating ZIP..."
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Compress-Archive -Path $packageRoot -DestinationPath $zipPath -Force

Write-Host "Package created: $zipPath"
Write-Host "Upload this file to a GitHub Release as LocalLM-windows-x64.zip."
