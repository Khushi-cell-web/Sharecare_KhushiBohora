# Launch Android emulator and wait for boot before running Flutter
# Run this before "flutter run" or selecting the emulator in VS Code
Set-Location -Path $PSScriptRoot

$env:ANDROID_HOME = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT = "D:\Android\Sdk"
$adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
$emulator = "$env:ANDROID_HOME\emulator\emulator.exe"

# Prefer Pixel_4 AVD explicitly for this project
$avdsRaw = & $emulator -list-avds 2>$null
$avds = @()
if ($avdsRaw) { $avds = ($avdsRaw -split "`r?`n" | Where-Object { $_ -and $_.Trim().Length -gt 0 } | ForEach-Object { $_.Trim() }) }
$avdName = $null
if ($avds -contains "Pixel_4") {
    $avdName = "Pixel_4"
} elseif ($avds.Count -gt 0) {
    $avdName = $avds[0]
}

if (-not $avdName) {
    Write-Host "ERROR: No Android Virtual Device (AVD) found. Create a 'Pixel_4' device in Android Studio > Device Manager." -ForegroundColor Red
    exit 1
}

# Check if emulator already running
$devices = & $adb devices 2>$null
if ($devices -match "emulator-\d+\s+device") {
    Write-Host "Emulator already running." -ForegroundColor Green
    exit 0
}

# Restart ADB only when no emulator is connected (faster than always restarting).
Write-Host "Restarting ADB..." -ForegroundColor Cyan
& $adb kill-server 2>$null
Start-Sleep -Seconds 2
& $adb start-server 2>$null
Start-Sleep -Seconds 1

# Launch emulator in background.
# For reliability, disable snapshot loading so the emulator does a fresh boot.
Write-Host "Launching $avdName emulator (fresh boot for stability)..." -ForegroundColor Cyan
$proc = Start-Process -FilePath $emulator -ArgumentList "-avd", $avdName, "-no-snapshot-load" -PassThru -WindowStyle Normal

# Wait for device to appear
$timeout = 120
$elapsed = 0
while ($elapsed -lt $timeout) {
    Start-Sleep -Seconds 3
    $elapsed += 3
    $devices = & $adb devices 2>$null
    $emuLine = ($devices -split "`n" | Where-Object { $_ -match "emulator-(\d+)\s+device" } | Select-Object -First 1)
    if ($emuLine) {
        $emuSerial = ($emuLine -split "\s+")[0]
        Write-Host "Emulator connected ($emuSerial). Waiting for boot..." -ForegroundColor Yellow
        & $adb -s $emuSerial wait-for-device
        $bootComplete = $false
        for ($i = 0; $i -lt 40; $i++) {
            $prop = & $adb -s $emuSerial shell getprop sys.boot_completed 2>$null
            if ($prop -match "1") { $bootComplete = $true; break }
            Start-Sleep -Seconds 2
        }
        if ($bootComplete) {
            Write-Host "Emulator ready! You can now run your Flutter app." -ForegroundColor Green
            exit 0
        }
    }
    Write-Host "  ... waiting ($elapsed s)" -ForegroundColor Gray
}

Write-Host "Timeout: Emulator did not boot in $timeout seconds." -ForegroundColor Red
exit 1
