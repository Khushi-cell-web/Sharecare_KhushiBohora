# Run Django migrations from project root
# Usage: .\run-migrations.ps1

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

# Navigate to backend
Set-Location -Path "$projectRoot\backend"

# Use only Drive D Python - no C: fallbacks
$pythonExe = $null
if (Test-Path "D:\Python313\python.exe") {
    $pythonExe = "D:\Python313\python.exe"
} elseif (Test-Path "D:\Python312\python.exe") {
    $pythonExe = "D:\Python312\python.exe"
} elseif (Test-Path "D:\Programs\Python\Python313\python.exe") {
    $pythonExe = "D:\Programs\Python\Python313\python.exe"
} elseif (Test-Path "D:\Programs\Python\Python312\python.exe") {
    $pythonExe = "D:\Programs\Python\Python312\python.exe"
} elseif (Test-Path "$projectRoot\venv\Scripts\python.exe") {
    $pythonExe = "$projectRoot\venv\Scripts\python.exe"
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonExe = "py"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonExe = "python"
}
if (-not $pythonExe) {
    Write-Host "ERROR: Python not found. Please install Python and add it to PATH, or run:" -ForegroundColor Red
    Write-Host "  py -m pip install -r backend\requirements.txt" -ForegroundColor Yellow
    Write-Host "  py backend\manage.py migrate" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using: $pythonExe" -ForegroundColor Cyan
& $pythonExe manage.py migrate
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Migrations completed." -ForegroundColor Green
