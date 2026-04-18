# Run ShareCare backend with Daphne (ASGI) for WebSocket support.
# From project root: .\run-backend.ps1
Set-Location -Path "$PSScriptRoot\backend"
# Use only Drive D Python - no C: fallbacks
$py = $null
if (Test-Path "D:\Python313\python.exe") { $py = "D:\Python313\python.exe" }
elseif (Test-Path "D:\Python312\python.exe") { $py = "D:\Python312\python.exe" }
elseif (Test-Path "D:\Programs\Python\Python313\python.exe") { $py = "D:\Programs\Python\Python313\python.exe" }
elseif (Test-Path "D:\Programs\Python\Python312\python.exe") { $py = "D:\Programs\Python\Python312\python.exe" }
elseif (Test-Path "$PSScriptRoot\venv\Scripts\python.exe") { $py = "$PSScriptRoot\venv\Scripts\python.exe" }
if ($py) { & $py -m daphne -b 0.0.0.0 -p 8000 sharecare_backend.asgi:application }
else { Write-Host "Python not found on D:. Install Python to D:\Python313 or D:\Python312." -ForegroundColor Red; exit 1 }
