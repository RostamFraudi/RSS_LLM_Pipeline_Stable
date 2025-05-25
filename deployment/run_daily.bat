@echo off
setlocal enabledelayedexpansion

:: ========================================
:: RSS + LLM Pipeline - Run Quotidien
:: ========================================

echo.
echo ==========================================
echo 🚀 RSS + LLM Pipeline - Run Quotidien
echo ==========================================
echo.

:: Configuration
set PROJECT_DIR=%~dp0
set DOCKER_DIR=%PROJECT_DIR%docker_service
set NODERED_URL=http://localhost:18880
set LLM_URL=http://localhost:15000

:: Couleurs
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set RED=[91m
set RESET=[0m

echo %BLUE%📂 Demarrage depuis: %DOCKER_DIR%%RESET%
echo.

:: ========================================
:: 1. DEMARRAGE SERVICES
:: ========================================

echo %YELLOW%🐳 [1/4] Demarrage des services...%RESET%

cd /d "%DOCKER_DIR%"
docker-compose up -d

if %errorlevel% neq 0 (
    echo %RED%❌ Echec demarrage services%RESET%
    pause
    exit /b 1
)

echo %GREEN%✅ Services demarres%RESET%
echo.

:: ========================================
:: 2. ATTENTE SERVICES
:: ========================================

echo %YELLOW%⏳ [2/4] Attente services...%RESET%

:: Attente LLM (30s max)
set /a count=0
:wait_llm
timeout /t 2 /nobreak >nul
curl -s -f %LLM_URL%/health >nul 2>&1
if %errorlevel% equ 0 goto llm_ready
set /a count+=1
if %count% gtr 15 (
    echo %RED%❌ LLM Service timeout%RESET%
    goto skip_llm
)
goto wait_llm

:llm_ready
echo %GREEN%✅ LLM Service pret%RESET%

:skip_llm
:: Attente Node-RED (20s max)
set /a count=0
:wait_nodered
timeout /t 2 /nobreak >nul
curl -s -f %NODERED_URL% >nul 2>&1
if %errorlevel% equ 0 goto nodered_ready
set /a count+=1
if %count% gtr 10 (
    echo %RED%❌ Node-RED timeout%RESET%
    goto skip_nodered
)
goto wait_nodered

:nodered_ready
echo %GREEN%✅ Node-RED pret%RESET%

:skip_nodered
echo.

:: ========================================
:: 3. OUVERTURE NODE-RED
:: ========================================

echo %YELLOW%🌐 [3/4] Ouverture Node-RED...%RESET%

start "" "%NODERED_URL%"
timeout /t 3 /nobreak >nul

echo %GREEN%✅ Interface ouverte%RESET%
echo.

:: ========================================
:: 4. INFORMATIONS
:: ========================================

echo %YELLOW%📋 [4/4] Informations%RESET%
echo.
echo %GREEN%🎉 Pipeline RSS + LLM operationnel%RESET%
echo.
echo %BLUE%🔗 Liens:%RESET%
echo   • Node-RED: %NODERED_URL%
echo   • LLM Health: %LLM_URL%/health
echo.
echo %BLUE%📊 Etat conteneurs:%RESET%
docker-compose ps
echo.

echo %YELLOW%👀 Voir les logs ? (O/N)%RESET%
set /p "choice=Choix: "
if /i "%choice%"=="O" (
    docker-compose logs -f
) else (
    echo %GREEN%✅ Pipeline pret pour la journee !%RESET%
)

echo.
pause >nul
