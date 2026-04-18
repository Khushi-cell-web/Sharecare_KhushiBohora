# Run ShareCare Flutter app on Pixel 4 emulator
# Usage: In VS Code terminal, run: .\run_pixel4.ps1

Set-Location $PSScriptRoot

# 1. List emulators and launch Pixel 4 if available
Write-Host "Checking emulators..." -ForegroundColor Cyan
$emulators = & "D:\Flutter\bin\flutter.bat" emulators 2>&1
Write-Host $emulators

# Try to launch Pixel 4 (common AVD names)
$pixel4Ids = @("Pixel_4_API_34", "Pixel_4_API_33", "Pixel_4_API_31", "Pixel_4")
$launched = $false
foreach ($id in $pixel4Ids) {
    if ($emulators -match $id) {
        Write-Host "Launching $id..." -ForegroundColor Green
        Start-Process -FilePath "D:\Flutter\bin\flutter.bat" -ArgumentList "emulators", "--launch", $id -NoNewWindow -Wait
        $launched = $true
        break
    }
}

if (-not $launched) {
    Write-Host "Pixel 4 emulator not found in list. Make sure you have created a Pixel 4 AVD in Android Studio (AVD Manager)." -ForegroundColor Yellow
    Write-Host "Running on any available Android device/emulator..." -ForegroundColor Yellow
}

# 2. Wait a few seconds for emulator to boot
Start-Sleep -Seconds 5

# 3. Run the app
Write-Host "Starting Flutter app..." -ForegroundColor Cyan
& "D:\Flutter\bin\flutter.bat" run -d android
