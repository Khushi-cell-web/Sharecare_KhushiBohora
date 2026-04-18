# Run ShareCare on a physical Android phone with safer memory settings.
# Usage: .\run_phone.ps1 -DeviceId CPH2119

param(
    [string]$DeviceId = "CPH2119"
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

# Tooling paths on D: drive.
$env:JAVA_HOME = "D:\Java\jdk-17.0.18.8-hotspot"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT = "D:\Android\Sdk"
$env:PUB_CACHE = "D:\PubCache"
$env:GRADLE_USER_HOME = "D:\GradleCache\.gradle"

# Keep tool memory conservative and avoid JVM native OOM crashes on Windows.
$env:DART_VM_OPTIONS = "--old_gen_heap_size=3072"

# Clear inherited Java/Gradle overrides that can force unstable heaps.
Remove-Item Env:JAVA_TOOL_OPTIONS -ErrorAction SilentlyContinue
Remove-Item Env:GRADLE_OPTS -ErrorAction SilentlyContinue
Remove-Item Env:_JAVA_OPTIONS -ErrorAction SilentlyContinue

# Force safer Gradle JVM and worker settings for this run.
$safeGradleJvmArgs = "-Xms256m -Xmx1024m -XX:MaxMetaspaceSize=320m -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -XX:CICompilerCount=2 -Xss512k -XX:HeapBaseMinAddress=1G -Dfile.encoding=UTF-8"
$env:ORG_GRADLE_PROJECT_org_gradle_jvmargs = $safeGradleJvmArgs
$env:ORG_GRADLE_PROJECT_org_gradle_workers_max = "1"
$env:ORG_GRADLE_PROJECT_kotlin_daemon_enabled = "false"
$env:ORG_GRADLE_PROJECT_kotlin_compiler_execution_strategy = "in-process"

$flutterPath = if (Test-Path "D:\Flutter\bin\flutter.bat") {
    "D:\Flutter\bin\flutter.bat"
} elseif (Test-Path "D:\flutter\bin\flutter.bat") {
    "D:\flutter\bin\flutter.bat"
} else {
    "flutter"
}

$adb = "$env:ANDROID_HOME\platform-tools\adb.exe"

Write-Host "Restarting ADB server..." -ForegroundColor Cyan
& $adb kill-server | Out-Null
& $adb start-server | Out-Null

Write-Host "Connected devices:" -ForegroundColor Cyan
& $adb devices

Write-Host "Stopping stale Gradle daemons..." -ForegroundColor Cyan
Push-Location (Join-Path $PSScriptRoot "android")
& .\gradlew.bat --stop | Out-Null
Pop-Location

# Fix intermittent "Invalid depfile ... kernel_snapshot_program.d" after aborted runs.
$flutterBuildCache = Join-Path $PSScriptRoot ".dart_tool\flutter_build"
if (Test-Path $flutterBuildCache) {
    Write-Host "Clearing stale Flutter incremental cache..." -ForegroundColor Cyan
    Remove-Item -Path $flutterBuildCache -Recurse -Force -ErrorAction SilentlyContinue
}

# Auto-detect host LAN IP and pass it to Flutter as a dart-define so physical
# device builds always target the current backend IP even when DHCP changes it.
$hostLanIp = $null
try {
    $defaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop |
        Sort-Object RouteMetric |
        Select-Object -First 1

    if ($null -ne $defaultRoute) {
        $candidate = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $defaultRoute.InterfaceIndex -ErrorAction Stop |
            Where-Object { $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -ne "127.0.0.1" } |
            Select-Object -First 1
        $hostLanIp = $candidate.IPAddress
    }
}
catch {
    $hostLanIp = $null
}

if ([string]::IsNullOrWhiteSpace($hostLanIp)) {
    $hostLanIp = "192.168.16.106"
}

$apiBaseUrl = "http://${hostLanIp}:8000"
Write-Host "Using backend URL for this run: $apiBaseUrl" -ForegroundColor Cyan

Write-Host "Running Flutter on $DeviceId with low-memory debug flags..." -ForegroundColor Green
& $flutterPath run -d $DeviceId --dart-define "API_BASE_URL=$apiBaseUrl" --no-track-widget-creation --no-dds --no-android-gradle-daemon
