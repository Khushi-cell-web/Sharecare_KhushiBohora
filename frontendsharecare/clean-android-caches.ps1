# Clean Android/Gradle/Kotlin caches to fix "different roots" and red error in IDE.
# Run from: D:\FYP Sharecare\frontendsharecare
# Usage: .\clean-android-caches.ps1

$ErrorActionPreference = 'SilentlyContinue'
$root = $PSScriptRoot

Write-Host "Cleaning build and caches..." -ForegroundColor Cyan
Remove-Item -Path "$root\build" -Recurse -Force
Remove-Item -Path "$root\android\.gradle" -Recurse -Force
Remove-Item -Path "$root\android\.kotlin" -Recurse -Force
Remove-Item -Path "$root\android\hs_err_pid*.log" -Force
Remove-Item -Path "$root\android\replay_pid*.log" -Force
Write-Host "Done. Re-open the project or run 'flutter pub get' and build again." -ForegroundColor Green
