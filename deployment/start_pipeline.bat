@echo off
setlocal enabledelayedexpansion
echo ============================================
echo     Pipeline RSS + LLM - Version Portable
echo ============================================
echo.

:: Navigation portable
cd /d "%~dp0.."

echo Repertoire: %CD%
echo Architecture: %PROCESSOR_ARCHITECTURE%
echo.

:: Verifications systeme
echo [1/6] Verification Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker non detecte
    echo Installez Docker Desktop depuis docker.com
    pause & exit /b 1
)
echo Docker OK

echo [2/6] Verification Docker Compose...
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker Compose manquant
    pause & exit /b 1
)
echo Docker Compose OK

:: Verification structure portable
echo [3/6] Verification structure...
if not exist "docker_service\docker-compose.yml" (
    echo Structure incorrecte - docker-compose.yml manquant
    echo Attendu: docker_service\docker-compose.yml
    pause & exit /b 1
)
if not exist "config\sources.json" (
    echo Configuration manquante - sources.json
    pause & exit /b 1
)
echo Structure validee

:: Nettoyage services existants
echo [4/6] Nettoyage services...
cd docker_service
docker-compose down -v >nul 2>&1
echo Nettoyage termine

echo [5/6] Options demarrage...
echo Voulez-vous un nettoyage Docker complet ATTENTION choix lourd de conséquence !? (y/N)
set /p cleanup="Reponse: "
if /i "%cleanup%"=="y" (
    echo Nettoyage Docker...
    docker system prune -f >nul 2>&1
    echo Nettoyage termine
)

:: Demarrage services
echo [6/6] Lancement pipeline...
echo.
echo Demarrage (3-5 min pour premier build)
echo Patience pendant telechargement modeles...
echo.

docker-compose up --build -d
if %errorlevel% neq 0 (
    echo Erreur demarrage
    echo Logs d'erreur:
    docker-compose logs --tail=10
    pause & exit /b 1
)

:: Attente intelligente
echo Verification demarrage...
set /a attempts=0
:check_loop
set /a attempts=%attempts%+1
echo [Tentative %attempts%/20] Test services...

curl -s http://localhost:15000/health >nul 2>&1
set llm_ok=%errorlevel%
curl -s http://localhost:18880 >nul 2>&1  
set nodered_ok=%errorlevel%

if %llm_ok% equ 0 if %nodered_ok% equ 0 goto success

if %attempts% geq 20 (
    echo Timeout demarrage
    docker-compose ps
    pause & exit /b 1
)

timeout /t 10 /nobreak >nul
goto check_loop

:success
echo.
echo SUCCES - Pipeline operationnel !
echo.
echo Statut final:
docker-compose ps
echo.
echo Services disponibles:
echo • LLM Service: http://localhost:15000/health
echo • Node-RED: http://localhost:18880
echo.
echo Emplacements:
echo • Articles: %CD%\..\obsidian_vault\articles\
echo • Config: %CD%\..\config\sources.json
echo.
echo Prochaines etapes:
echo 1. Ouvrir Node-RED: http://localhost:18880
echo 2. Importer votre flow JSON
echo 3. Configurer Obsidian sur obsidian_vault\
echo 4. Tester le pipeline
echo.
pause