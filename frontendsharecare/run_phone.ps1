# Run ShareCare on a physical Android phone with safer memory settings.
# Usage: .\run_phone.ps1 -DeviceId CPH2119

param(
    [string]$DeviceId = "CPH2119",
    [string]$ApiBaseUrl = ""
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
$adbDevicesOutput = & $adb devices
$adbDevicesOutput

$connectedDeviceIds = @(
    $adbDevicesOutput |
        Select-Object -Skip 1 |
        Where-Object { $_ -match "\sdevice$" } |
        ForEach-Object { ($_ -split "\s+")[0] } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)

if ($connectedDeviceIds.Count -eq 0) {
    throw "No connected Android devices found by adb."
}

if (-not ($connectedDeviceIds -contains $DeviceId)) {
    $originalDeviceId = $DeviceId
    $DeviceId = $connectedDeviceIds[0]
    Write-Host "Requested DeviceId '$originalDeviceId' was not found. Using connected device '$DeviceId' instead." -ForegroundColor Yellow
}

$adbReverseReady = $false
try {
    Write-Host "Configuring adb reverse (device localhost:8000 -> PC localhost:8000)..." -ForegroundColor Cyan
    & $adb -s $DeviceId reverse tcp:8000 tcp:8000 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $adbReverseReady = $true
        Write-Host "adb reverse configured successfully." -ForegroundColor Green
    }
} catch {
    Write-Host "adb reverse setup failed; will fall back to LAN URL detection." -ForegroundColor Yellow
}

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

# Resolve backend URL without Get-NetRoute/Get-NetIPAddress, which can block on
# some Windows setups with many virtual adapters.
function Get-PreferredLocalIPv4 {
    try {
        $socket = New-Object System.Net.Sockets.Socket(
            [System.Net.Sockets.AddressFamily]::InterNetwork,
            [System.Net.Sockets.SocketType]::Dgram,
            [System.Net.Sockets.ProtocolType]::Udp
        )
        $socket.Connect("8.8.8.8", 53)
        $ip = $socket.LocalEndPoint.Address.ToString()
        $socket.Dispose()

        if (-not [string]::IsNullOrWhiteSpace($ip) -and $ip -ne "127.0.0.1" -and $ip -notlike "169.254.*") {
            return $ip
        }
    }
    catch {
        # Fall through to interface enumeration.
    }

    try {
        $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
            Where-Object {
                $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback
            }

        foreach ($nic in $nics) {
            foreach ($ua in $nic.GetIPProperties().UnicastAddresses) {
                if ($ua.Address.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    continue
                }

                $ip = $ua.Address.ToString()
                if ($ip -ne "127.0.0.1" -and $ip -notlike "169.254.*") {
                    return $ip
                }
            }
        }
    }
    catch {
        # Keep null and allow caller fallback.
    }

    return $null
}

function Get-ActiveLocalIPv4s {
    $ips = @()
    try {
        $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
            Where-Object {
                $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
                $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback
            }

        foreach ($nic in $nics) {
            foreach ($ua in $nic.GetIPProperties().UnicastAddresses) {
                if ($ua.Address.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    continue
                }

                $ip = $ua.Address.ToString()
                if ($ip -ne "127.0.0.1" -and $ip -notlike "169.254.*") {
                    $ips += $ip
                }
            }
        }
    }
    catch {
        return @()
    }

    return $ips | Sort-Object -Unique
}

$resolvedApiBaseUrl = $ApiBaseUrl

if ([string]::IsNullOrWhiteSpace($resolvedApiBaseUrl) -and $adbReverseReady) {
    # Most stable option for USB debug runs: bypass Wi-Fi and firewall entirely.
    $resolvedApiBaseUrl = "http://127.0.0.1:8000"
}

if ([string]::IsNullOrWhiteSpace($resolvedApiBaseUrl)) {
    # Prefer API_BASE_URL from assets/.env when explicitly set.
    $envFile = Join-Path $PSScriptRoot "assets\.env"
    if (Test-Path $envFile) {
        $apiLine = Get-Content $envFile |
            Where-Object { $_ -match '^\s*API_BASE_URL\s*=' } |
            Select-Object -First 1

        if (-not [string]::IsNullOrWhiteSpace($apiLine)) {
            $fromEnv = ($apiLine -split '=', 2)[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($fromEnv)) {
                $lower = $fromEnv.ToLowerInvariant()
                if ($lower -ne 'auto' -and $lower -ne 'default') {
                    if ($fromEnv -notmatch '^https?://') {
                        $fromEnv = "http://$fromEnv"
                    }
                    try {
                        $uri = [Uri]$fromEnv
                        $envHost = $uri.Host
                        $activeIps = Get-ActiveLocalIPv4s
                        if ($activeIps -contains $envHost) {
                            $resolvedApiBaseUrl = $fromEnv
                        }
                        else {
                            Write-Host "Ignoring stale API_BASE_URL host '$envHost' (not an active local IPv4)." -ForegroundColor Yellow
                        }
                    }
                    catch {
                        Write-Host "Ignoring invalid API_BASE_URL in .env: $fromEnv" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
}

if ([string]::IsNullOrWhiteSpace($resolvedApiBaseUrl)) {
    $hostLanIp = Get-PreferredLocalIPv4

    if ([string]::IsNullOrWhiteSpace($hostLanIp)) {
        $hostLanIp = "192.168.16.106"
    }

    $resolvedApiBaseUrl = "http://${hostLanIp}:8000"
}

Write-Host "Using backend URL for this run: $resolvedApiBaseUrl" -ForegroundColor Cyan

Write-Host "Running Flutter on $DeviceId with low-memory debug flags..." -ForegroundColor Green
& $flutterPath run -d $DeviceId --dart-define "API_BASE_URL=$resolvedApiBaseUrl" --no-track-widget-creation --no-dds --no-android-gradle-daemon
