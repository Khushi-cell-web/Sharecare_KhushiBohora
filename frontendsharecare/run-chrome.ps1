# Run ShareCare on Chrome OUTSIDE the VS Code integrated terminal if the IDE feels stuck.
# Usage: right-click -> Run with PowerShell, or:  powershell -ExecutionPolicy Bypass -File .\run-chrome.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Write-Host "Directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host "First web build can take several minutes; please wait..." -ForegroundColor Yellow
flutter pub get
flutter run -d chrome
