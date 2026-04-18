# Run ShareCare Flutter app on Android emulator
# All tools on D: drive
Set-Location -Path $PSScriptRoot
$env:JAVA_HOME = "D:\Java\jdk-17.0.18.8-hotspot"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT = "D:\Android\Sdk"
$env:PUB_CACHE = "D:\PubCache"
$env:GRADLE_USER_HOME = "D:\GradleCache\.gradle"
$flutterPath = if (Test-Path "D:\Flutter\bin\flutter.bat") { "D:\Flutter\bin\flutter.bat" } elseif (Test-Path "D:\flutter\bin\flutter.bat") { "D:\flutter\bin\flutter.bat" } else { "flutter" }
$adb = "$env:ANDROID_HOME\platform-tools\adb.exe"

# Ensure emulator is running - launch if not
$devices = & $adb devices 2>$null
if (-not ($devices -match "emulator-\d+\s+device")) {
    Write-Host "Starting emulator (run .\launch-emulator.ps1 first if this fails)..." -ForegroundColor Yellow
    & "$PSScriptRoot\launch-emulator.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Emulator failed to start. Try running .\launch-emulator.ps1 manually first." -ForegroundColor Red
        exit 1
    }
}

$targetSerial = "emulator-5554"
Write-Host "Running Flutter on $targetSerial..." -ForegroundColor Cyan
& $flutterPath run -d $targetSerial
