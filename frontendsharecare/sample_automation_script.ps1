param(
    [string]$ProjectRoot = "D:\FYP Sharecare\frontendsharecare",
    [string]$LogFile = "D:\FYP Sharecare\frontendsharecare\automation.log"
)

function Write-Log {
    param(
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $entry
    Write-Host $entry
}

function Assert-PathExists {
    param(
        [string]$PathToCheck,
        [string]$Label
    )

    if (-not (Test-Path $PathToCheck)) {
        throw "$Label not found: $PathToCheck"
    }
}

try {
    Write-Log "Starting automation script"

    Assert-PathExists -PathToCheck $ProjectRoot -Label "Project root"
    Assert-PathExists -PathToCheck (Join-Path $ProjectRoot "run-backend.ps1") -Label "Backend script"
    Assert-PathExists -PathToCheck (Join-Path $ProjectRoot "frontendsharecare\run-chrome.ps1") -Label "Flutter web script"

    Write-Log "Starting backend"
    Start-Process powershell.exe -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $ProjectRoot "run-backend.ps1")
    )

    Start-Sleep -Seconds 5

    Write-Log "Starting Flutter web app"
    Start-Process powershell.exe -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $ProjectRoot "frontendsharecare\run-chrome.ps1")
    )

    Write-Log "Automation script completed successfully"
}
catch {
    Write-Log "Automation script failed: $($_.Exception.Message)"
    throw
}