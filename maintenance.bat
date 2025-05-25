@echo off
setlocal enabledelayedexpansion

:: ========================================
:: RSS + LLM Pipeline - Maintenance  
:: ========================================

echo.
echo ==========================================
echo 🧹 RSS + LLM Pipeline - Maintenance
echo ==========================================
echo.

:: Configuration
set PROJECT_DIR=%~dp0
set DOCKER_DIR=%PROJECT_DIR%docker_service
set ARTICLES_DIR=%PROJECT_DIR%obsidian_vault\articles

:: Couleurs
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set RESET=[0m

echo %BLUE%📂 Repertoire projet: %PROJECT_DIR%%RESET%
echo.

:menu
echo %YELLOW%🛠️  === MENU MAINTENANCE ===%RESET%
echo.
echo   1. 🧹 Nettoyer les logs Docker
echo   2. 📁 Archiver anciens articles (+ 30 jours)
echo   3. 🔄 Rebuild complet des services
echo   4. 🗑️  Nettoyer images Docker inutilisees
echo   5. 📊 Statistiques detaillees
echo   6. 🔧 Reparation rapide
echo   0. ❌ Quitter
echo.
set /p "choice=Choix (0-6): "

if "%choice%"=="1" goto clean_logs
if "%choice%"=="2" goto archive_articles  
if "%choice%"=="3" goto rebuild_services
if "%choice%"=="4" goto clean_docker
if "%choice%"=="5" goto detailed_stats
if "%choice%"=="6" goto quick_repair
if "%choice%"=="0" goto end
goto menu

:: ========================================
:: NETTOYAGE LOGS
:: ========================================
:clean_logs
echo.
echo %YELLOW%🧹 Nettoyage des logs Docker...%RESET%
cd /d "%DOCKER_DIR%"

echo %BLUE%📊 Taille logs avant nettoyage:%RESET%
docker system df

echo %BLUE%🗑️  Suppression logs anciens...%RESET%
docker system prune -f --volumes

echo %GREEN%✅ Logs nettoyes%RESET%
echo.
goto menu

:: ========================================  
:: ARCHIVAGE ARTICLES
:: ========================================
:archive_articles
echo.
echo %YELLOW%📁 Archivage des anciens articles...%RESET%

if not exist "%ARTICLES_DIR%" (
    echo %RED%❌ Dossier articles non trouve%RESET%
    goto menu
)

:: Créer dossier archive
set ARCHIVE_DIR=%PROJECT_DIR%obsidian_vault\archives\%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%
if not exist "%ARCHIVE_DIR%" mkdir "%ARCHIVE_DIR%"

echo %BLUE%📦 Archivage articles + 30 jours dans: %ARCHIVE_DIR%%RESET%

:: Déplacer fichiers anciens (PowerShell pour gestion dates)
powershell -Command "Get-ChildItem -Path '%ARTICLES_DIR%' -Recurse -File -Name '*.md' | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Move-Item -Destination '%ARCHIVE_DIR%'"

echo %GREEN%✅ Articles archives%RESET%
echo.
goto menu

:: ========================================
:: REBUILD SERVICES  
:: ========================================
:rebuild_services
echo.
echo %YELLOW%🔄 Rebuild complet des services...%RESET%
cd /d "%DOCKER_DIR%"

echo %BLUE%🛑 Arret services...%RESET%
docker-compose down

echo %BLUE%🗑️  Suppression images existantes...%RESET%
docker rmi rss_llm_pipeline_stable_llm-service rss_llm_pipeline_stable_nodered 2>nul

echo %BLUE%🔨 Rebuild et redemarrage...%RESET%
docker-compose up --build -d

echo %GREEN%✅ Services rebuildes%RESET%
echo.
goto menu

:: ========================================
:: NETTOYAGE DOCKER
:: ========================================  
:clean_docker
echo.
echo %YELLOW%🗑️  Nettoyage images Docker...%RESET%

echo %BLUE%📊 Espace avant nettoyage:%RESET%
docker system df

echo %BLUE%🧹 Suppression images non utilisees...%RESET%
docker image prune -f

echo %BLUE%🧹 Suppression conteneurs arretes...%RESET%
docker container prune -f

echo %GREEN%✅ Docker nettoye%RESET%
echo.
goto menu

:: ========================================
:: STATISTIQUES DETAILLEES
:: ========================================
:detailed_stats
echo.
echo %YELLOW%📊 Statistiques detaillees...%RESET%

echo %BLUE%📈 === ARTICLES GENERES ===%RESET%
if exist "%ARTICLES_DIR%" (
    for /d %%d in ("%ARTICLES_DIR%\*") do (
        set "count=0"
        for %%f in ("%%d\*.md") do set /a count+=1
        echo   %%~nxd: !count! articles
    )
) else (
    echo %RED%❌ Dossier articles non trouve%RESET%
)

echo.
echo %BLUE%💾 === UTILISATION DISQUE ===%RESET%
for /f "tokens=3" %%a in ('dir /-c "%PROJECT_DIR%" ^| find "bytes"') do echo   Projet: %%a bytes

echo.
echo %BLUE%🐳 === RESSOURCES DOCKER ===%RESET%
docker system df

echo.
echo %BLUE%⏱️  === UPTIME CONTENEURS ===%RESET%
docker ps --format "table {{.Names}}\t{{.Status}}"

echo.
goto menu

:: ========================================
:: REPARATION RAPIDE
:: ========================================
:quick_repair
echo.
echo %YELLOW%🔧 Reparation rapide...%RESET%
cd /d "%DOCKER_DIR%"

echo %BLUE%🔄 Restart des services...%RESET%
docker-compose restart

echo %BLUE%⏳ Attente services (30s)...%RESET%
timeout /t 30 /nobreak >nul

echo %BLUE%🏥 Test sante services...%RESET%
curl -s -f http://localhost:15000/health >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅ LLM Service: OK%RESET%
) else (
    echo %RED%❌ LLM Service: ERREUR%RESET%
)

curl -s -f http://localhost:18880 >nul  
if %errorlevel% equ 0 (
    echo %GREEN%✅ Node-RED: OK%RESET%
) else (
    echo %RED%❌ Node-RED: ERREUR%RESET%
)

echo %GREEN%✅ Reparation terminee%RESET%
echo.
goto menu

:end
echo.
echo %GREEN%👋 Maintenance terminee !%RESET%
echo.
pause
