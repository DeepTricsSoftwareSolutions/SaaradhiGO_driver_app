@echo off
REM SaaradhiGO Driver App - Windows Setup & Run Script

setlocal enabledelayedexpansion

echo.
echo ===============================================
echo   SaaradhiGO Driver App - Setup and Run
echo ===============================================
echo.

REM Check Node.js
echo Checking prerequisites...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not installed. Please install Node.js v18+
    pause
    exit /b 1
)
echo OK: Node.js found

npm --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm not installed.
    pause
    exit /b 1
)
echo OK: npm found

REM Install dependencies
echo.
echo Installing dependencies...
if not exist "node_modules" (
    echo Installing root packages...
    call npm install
) else (
    echo Root dependencies already installed
)

if not exist "server\node_modules" (
    echo Installing backend packages...
    cd server
    call npm install
    cd ..
) else (
    echo Backend dependencies already installed
)

echo.
echo ===============================================
echo   Setup Options
echo ===============================================
echo 1 - Start Backend Server (Port 8000)
echo 2 - Start Mobile App (Flutter Web)
echo 3 - Start Both (Recommended)
echo 4 - Setup Database (Docker)
echo 5 - Run Migrations
echo 6 - Exit
echo.

set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" (
    echo.
    echo Starting Backend Server...
    echo.
    call npm run backend
) else if "%choice%"=="2" (
    echo.
    echo Starting Flutter Web App...
    echo.
    call npm run mobile
) else if "%choice%"=="3" (
    echo.
    echo Starting Backend + Mobile...
    echo.
    call npm run dev
) else if "%choice%"=="4" (
    echo.
    echo Starting PostgreSQL Docker Container...
    docker-compose -f server\docker-compose.yml up -d
    echo Database started (PostgreSQL on localhost:5432)
    echo.
    pause
) else if "%choice%"=="5" (
    echo.
    echo Running Database Migrations...
    cd server
    call npm run migrate
    cd ..
    echo.
    pause
) else if "%choice%"=="6" (
    echo Setup complete. Run: npm run dev
) else (
    echo Invalid choice!
)

pause
