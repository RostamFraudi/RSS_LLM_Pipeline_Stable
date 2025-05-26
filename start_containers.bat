@echo off
setlocal enabledelayedexpansion

:: ========================================
:: RSS + LLM Pipeline - Start Quotidien
:: ========================================

echo.
echo ==========================================
echo 🚀 RSS + LLM Pipeline - Start Quotidien  
echo ==========================================
echo.

:: URLs
set NODERED_URL=http://localhost:18880
set LLM_URL=http://localhost:15000

:: Couleurs
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set RED=[91m
set RESET=[0m

:: ========================================
:: DEMARRAGE DIRECT CONTENEURS
:: ========================================

echo %YELLOW%🐳 Demarrage conteneurs existants...%RESET%

docker start rss_llm_service_v3 rss_nodered

if %errorlevel% neq 0 (
    echo %RED%❌ Echec demarrage conteneurs%RESET%
    echo %BLUE%💡 Verifiez: docker ps -a%RESET%
    pause
    exit /b 1
)

echo %GREEN%✅ Conteneurs demarres%RESET%
echo.

:: ========================================
:: ATTENTE SERVICES
:: ========================================

echo %YELLOW%⏳ Attente services...%RESET%

:: LLM Service
set /a count=0
:wait_llm
timeout /t 2 /nobreak >nul
curl -s -f %LLM_URL%/health >nul 2>&1
if %errorlevel% equ 0 goto llm_ready
set /a count+=1
if %count% gtr 15 echo %YELLOW%  . LLM Service (%count%/15)%RESET%
if %count% gtr 15 goto skip_llm
goto wait_llm
:llm_ready
echo %GREEN%✅ LLM Service pret%RESET%
:skip_llm

:: Node-RED
set /a count=0
:wait_nodered
timeout /t 1 /nobreak >nul
curl -s -f %NODERED_URL% >nul 2>&1
if %errorlevel% equ 0 goto nodered_ready
set /a count+=1
if %count% gtr 10 echo %YELLOW%  . Node-RED (%count%/10)%RESET%
if %count% gtr 10 goto skip_nodered
goto wait_nodered
:nodered_ready
echo %GREEN%✅ Node-RED pret%RESET%
:skip_nodered

echo.

:: ========================================
:: OUVERTURE NODE-RED
:: ========================================

echo %YELLOW%🌐 Ouverture Node-RED...%RESET%

start "" "%NODERED_URL%"
timeout /t 2 /nobreak >nul

echo %GREEN%✅ Interface ouverte%RESET%
echo.

:: ========================================
:: INFORMATIONS
:: ========================================

echo %GREEN%🎉 Pipeline RSS + LLM operationnel%RESET%
echo.
echo %BLUE%🔗 Liens:%RESET%
echo   • Node-RED: %NODERED_URL%
echo   • LLM Health: %LLM_URL%/health
echo.
echo %BLUE%📊 Etat:%RESET%
docker ps --filter "name=rss_" --format "{{.Names}} - {{.Status}}"
echo.

echo %YELLOW%Voir logs ? (O/N): %RESET%
set /p "choice="
if /i "%choice%"=="O" (
    docker logs -f rss_llm_service
)

echo.
echo %GREEN%✅ Pret pour la journee !%RESET%
pause >nul
