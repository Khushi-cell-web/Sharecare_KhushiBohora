# Wrapper to run the frontend phone script from workspace root.
# Usage: .\run_phone.ps1 -DeviceId CPH2119

param(
    [string]$DeviceId = "CPH2119",
    [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"

$innerScript = Join-Path $PSScriptRoot "frontendsharecare\run_phone.ps1"
if (-not (Test-Path $innerScript)) {
    throw "Could not find phone runner script at: $innerScript"
}

& $innerScript -DeviceId $DeviceId -ApiBaseUrl $ApiBaseUrl
