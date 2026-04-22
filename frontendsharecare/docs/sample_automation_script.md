# Sample Automation Script

This file provides a simple PowerShell automation script example that you can use as a template for documenting or running routine tasks in this project.

## Sample Code

```powershell
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
```

## What It Does

1. Validates the project paths before starting anything.
2. Writes each step to a log file.
3. Starts the backend first.
4. Starts the Flutter web app after a short delay.

## Usage

Run the script from PowerShell:

```powershell
.\sample_automation_script.ps1
```

If you want, I can also create the matching `.ps1` file for this sample script.