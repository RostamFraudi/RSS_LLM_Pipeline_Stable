@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0.."

echo ============================================
echo     Tests Pipeline RSS + LLM - Portable
echo ============================================
echo.
echo Projet: %CD%
echo %date% %time%
echo.

:: Tests de base
set /a score=0
set /a total=6

echo === TESTS SYSTEME ===
echo.

echo [1/%total%] Docker Compose actif...
cd docker_service
docker-compose ps | findstr "Up" >nul
if %errorlevel% equ 0 (
    echo Services Docker actifs
    set /a score=%score%+1
) else (
    echo Services non actifs
)
cd ..

echo [2/%total%] LLM Service Health...
curl -s http://localhost:15000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo LLM accessible (port 15000)
    set /a score=%score%+1
) else (
    echo LLM inaccessible
)

echo [3/%total%] Node-RED Interface...
curl -s http://localhost:18880 >nul 2>&1
if %errorlevel% equ 0 (
    echo Node-RED accessible (port 18880)
    set /a score=%score%+1
) else (
    echo Node-RED inaccessible
)

echo [4/%total%] Structure fichiers...
if exist "config\sources.json" if exist "obsidian_vault\articles" (
    echo Structure OK
    set /a score=%score%+1
) else (
    echo Fichiers manquants
)

echo [5/%total%] Classification LLM V1...
curl -s -X POST http://localhost:15000/classify ^
  -H "Content-Type: application/json" ^
  -d "{\"title\":\"Test IA\",\"content\":\"Intelligence artificielle\"}" | findstr "category" >nul
if %errorlevel% equ 0 (
    echo Classification V1 OK
    set /a score=%score%+1
) else (
    echo Classification V1 echec
)

echo [6/%total%] Classification LLM V2...
curl -s -X POST http://localhost:15000/classify_v2 ^
  -H "Content-Type: application/json" ^
  -d "{\"title\":\"Securite\",\"content\":\"Breach vulnerability\",\"source\":\"security\"}" | findstr "domain" >nul
if %errorlevel% equ 0 (
    echo Classification V2 OK
    set /a score=%score%+1
) else (
    echo Classification V2 echec
)

echo.
echo === RESULTATS ===
echo.
set /a percentage=(%score%*100)/%total%
echo Score: %score%/%total% (%percentage%%%)

if %percentage% geq 90 (
    echo EXCELLENT - Pipeline parfait !
) else if %percentage% geq 70 (
    echo BON - Pipeline fonctionnel
) else (
    echo ATTENTION - Problemes detectes
)

echo.
echo Liens:
echo • LLM Status: http://localhost:15000/status
echo • Node-RED: http://localhost:18880
echo • Logs: docker-compose -f docker_service\docker-compose.yml logs
echo.
pause