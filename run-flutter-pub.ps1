# Run flutter pub get from project root
# Usage: .\run-flutter-pub.ps1

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

# Navigate to frontend
Set-Location -Path "$projectRoot\frontendsharecare"

# Prefer Flutter on D: - no C: fallback
$flutterCmd = $null
if (Test-Path "D:\Flutter\bin\flutter.bat") {
    $flutterCmd = "D:\Flutter\bin\flutter.bat"
} elseif (Test-Path "D:\flutter\bin\flutter.bat") {
    $flutterCmd = "D:\flutter\bin\flutter.bat"
} elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterCmd = "flutter"
}
if (-not $flutterCmd) {
    Write-Host "ERROR: Flutter not found. Add Flutter to PATH:" -ForegroundColor Red
    Write-Host "  1. Install Flutter from https://flutter.dev" -ForegroundColor Yellow
    Write-Host "  2. Add Flutter bin to PATH (e.g. D:\flutter\bin)" -ForegroundColor Yellow
    exit 1
}

# Use D: for Pub cache so no data stays on C:
$env:PUB_CACHE = "D:\PubCache"
Write-Host "Running flutter pub get in frontendsharecare (PUB_CACHE=D:\PubCache)..." -ForegroundColor Cyan
& $flutterCmd pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Done." -ForegroundColor Green
