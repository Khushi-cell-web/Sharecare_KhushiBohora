@echo off
REM Run ShareCare backend using system Python (bypasses broken venv).
cd /d "%~dp0"

REM Use system Python directly - avoids venv path corruption
set PYTHONPATH=%~dp0
set DJANGO_SETTINGS_MODULE=sharecare_backend.settings

echo Applying migrations...
"D:\Python313\python.exe" manage.py migrate
if errorlevel 1 (
  echo Migration failed.
  pause
  exit /b 1
)

echo.
echo Starting server at http://127.0.0.1:8000
"D:\Python313\python.exe" manage.py runserver 0.0.0.0:8000
