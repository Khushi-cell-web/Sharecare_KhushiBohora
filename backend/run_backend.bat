@echo off
REM Run migrations then start Django dev server for ShareCare backend.
cd /d "%~dp0"

REM Use venv if present (project root or backend)
if exist "..\venv\Scripts\activate.bat" call ..\venv\Scripts\activate.bat
if exist "venv\Scripts\activate.bat" call venv\Scripts\activate.bat

echo Applying migrations...
python manage.py migrate
if errorlevel 1 (
  echo Migration failed. Try: python manage.py makemigrations
  pause
  exit /b 1
)

echo.
echo Starting server on 0.0.0.0:8000 (reachable from phone on same Wi‑Fi — use PC IPv4 in app .env)
echo Local browser: http://127.0.0.1:8000
python manage.py runserver 0.0.0.0:8000
