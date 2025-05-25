@echo off
setlocal enabledelayedexpansion

:: ========================================
:: RSS + LLM Pipeline - Diagnostic
:: ========================================

echo.
echo ==========================================
echo 🔍 RSS + LLM Pipeline - Diagnostic
echo ==========================================
echo.

:: Configuration
set PROJECT_DIR=%~dp0
set DOCKER_DIR=%PROJECT_DIR%docker_service

:: Couleurs
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set RESET=[0m

echo %BLUE%📂 Repertoire projet: %PROJECT_DIR%%RESET%
echo.

cd /d "%DOCKER_DIR%"

:: ========================================
:: ETAT DOCKER
:: ========================================

echo %YELLOW%🐳 === ETAT DOCKER ===%RESET%
echo.

echo %BLUE%📊 Version Docker:%RESET%
docker version --format "Client: {{.Client.Version}} | Server: {{.Server.Version}}"
echo.

echo %BLUE%📋 Conteneurs RSS Pipeline:%RESET%
docker ps -a --filter "name=rss_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.

echo %BLUE%💾 Ressources utilisees:%RESET%
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo.

:: ========================================
:: SANTE SERVICES
:: ========================================

echo %YELLOW%🏥 === SANTE SERVICES ===%RESET%
echo.

echo %BLUE%🤖 Test LLM Service:%RESET%
curl -s -f http://localhost:15000/health
if %errorlevel% equ 0 (
    echo %GREEN%✅ LLM Service: OK%RESET%
) else (
    echo %RED%❌ LLM Service: ERREUR%RESET%
)
echo.

echo %BLUE%🔧 Test Node-RED:%RESET%
curl -s -f http://localhost:18880 >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅ Node-RED: OK%RESET%
) else (
    echo %RED%❌ Node-RED: ERREUR%RESET%
)
echo.

:: ========================================
:: LOGS RECENTS
:: ========================================

echo %YELLOW%📜 === LOGS RECENTS ===%RESET%
echo.

echo %BLUE%🤖 Derniers logs LLM Service (10 lignes):%RESET%
docker-compose logs --tail=10 llm-service 2>nul
echo.

echo %BLUE%🔧 Derniers logs Node-RED (10 lignes):%RESET%
docker-compose logs --tail=10 nodered 2>nul
echo.

:: ========================================
:: FICHIERS GENERES
:: ========================================

echo %YELLOW%📁 === FICHIERS GENERES ===%RESET%
echo.

echo %BLUE%📊 Articles par categorie:%RESET%
if exist "%PROJECT_DIR%obsidian_vault\articles" (
    for /d %%d in ("%PROJECT_DIR%obsidian_vault\articles\*") do (
        set "count=0"
        for %%f in ("%%d\*.md") do set /a count+=1
        echo   %%~nxd: !count! articles
    )
) else (
    echo %RED%❌ Dossier articles non trouve%RESET%
)
echo.

echo %BLUE%📝 Derniers articles (5 plus recents):%RESET%
if exist "%PROJECT_DIR%obsidian_vault\articles" (
    forfiles /p "%PROJECT_DIR%obsidian_vault\articles" /s /m *.md /c "cmd /c echo @fdate @ftime - @path" 2>nul | sort /r | head -5
) else (
    echo %RED%❌ Aucun article trouve%RESET%
)
echo.

:: ========================================
:: CONFIGURATION
:: ========================================

echo %YELLOW%⚙️  === CONFIGURATION ===%RESET%
echo.

echo %BLUE%📋 Sources RSS configurees:%RESET%
if exist "%PROJECT_DIR%config\sources.json" (
    powershell -Command "(Get-Content '%PROJECT_DIR%config\sources.json' | ConvertFrom-Json).Length"
    echo sources configurees
) else (
    echo %RED%❌ Fichier sources.json non trouve%RESET%
)
echo.

echo %BLUE%🎯 Prompts LLM configures:%RESET%
if exist "%PROJECT_DIR%config\prompts.json" (
    echo %GREEN%✅ Fichier prompts.json present%RESET%
) else (
    echo %RED%❌ Fichier prompts.json non trouve%RESET%
)
echo.

:: ========================================
:: RECOMMENDATIONS
:: ========================================

echo %YELLOW%💡 === RECOMMENDATIONS ===%RESET%
echo.

:: Vérifier l'espace disque
for /f "tokens=3" %%a in ('dir /-c "%PROJECT_DIR%" ^| find "bytes free"') do set freespace=%%a
echo %BLUE%💾 Espace disque libre: %freespace% bytes%RESET%

:: Vérifier les ports
netstat -an | find ":15000" >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅ Port 15000 (LLM) ecoute%RESET%
) else (
    echo %RED%❌ Port 15000 (LLM) non disponible%RESET%
)

netstat -an | find ":18880" >nul
if %errorlevel% equ 0 (
    echo %GREEN%✅ Port 18880 (Node-RED) ecoute%RESET%
) else (
    echo %RED%❌ Port 18880 (Node-RED) non disponible%RESET%
)

echo.
echo %BLUE%🔗 Actions recommandees:%RESET%
echo   • Logs complets: docker-compose logs -f
echo   • Restart LLM: docker-compose restart llm-service  
echo   • Restart Node-RED: docker-compose restart nodered
echo   • Interface Node-RED: http://localhost:18880
echo   • Health LLM: http://localhost:15000/health

echo.
echo %GREEN%✅ Diagnostic termine%RESET%
echo.
pause
