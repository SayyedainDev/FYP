@echo off
REM Flutter Web Debugger Connection Fix Script
REM This script resolves "Failed to establish connection with the application instance in Chrome" error

echo ===================================
echo Flutter Web Connection Troubleshooting
echo ===================================
echo.

echo Step 1: Killing Chrome processes...
taskkill /F /IM chrome.exe /T >nul 2>&1
timeout /t 2 /nobreak
echo Chrome processes terminated.
echo.

echo Step 2: Cleaning Flutter cache...
cd "c:\Users\Sabeeh\Documents\GitHub\New folder\FYP\dental_care"
flutter clean
echo Flutter cache cleaned.
echo.

echo Step 3: Getting dependencies...
flutter pub get
echo Dependencies installed.
echo.

echo Step 4: Running on Chrome (Release Mode - More Stable)...
echo Starting app on http://localhost:8080
echo.
flutter run -d chrome --release

pause
