@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0.."

echo ============================================
echo   Tests Pipeline RSS + LLM - Version Stable
echo ============================================
echo.
echo 📁 Répertoire de travail: %CD%
echo ⏰ Timestamp: %date% %time%
echo.

:: Variables de couleur (simulation)
set SUCCESS=✅
set ERROR=❌
set WARNING=⚠️
set INFO=ℹ️

echo 🔍 === TESTS DE CONNECTIVITE ===
echo.

echo [1/6] Test Docker Compose Status...
cd docker_service
docker-compose ps
cd ..
echo.

echo [2/6] Test service LLM Health...
curl -s http://localhost:15000/health
set llm_health=%errorlevel%
if %llm_health% equ 0 (
    echo %SUCCESS% Service LLM accessible sur le port 15000
) else (
    echo %ERROR% Service LLM inaccessible
)
echo.

echo [3/6] Test service LLM Status détaillé...
echo 📋 Status complet:
curl -s http://localhost:15000/status
echo.
echo.

echo [4/6] Test Node-RED Interface...
curl -s http://localhost:18880 >nul
set nodered_status=%errorlevel%
if %nodered_status% equ 0 (
    echo %SUCCESS% Node-RED accessible sur le port 18880
    echo 🌐 Interface: http://localhost:18880
) else (
    echo %ERROR% Node-RED inaccessible
)
echo.

echo [5/6] Test Classification LLM (V1)...
echo 🧪 Test avec article IA...
curl -s -X POST http://localhost:15000/classify ^
  -H "Content-Type: application/json" ^
  -d "{\"title\":\"Test AI Article\",\"content\":\"This is about artificial intelligence and machine learning algorithms.\"}"
echo.
echo.

echo [6/6] Test Classification LLM (V2)...
echo 🧪 Test avec nouvelle API V2...
curl -s -X POST http://localhost:15000/classify_v2 ^
  -H "Content-Type: application/json" ^
  -d "{\"title\":\"Cybersecurity Breach\",\"content\":\"Major security vulnerability discovered in popular software.\",\"source\":\"security-news\"}"
echo.
echo.

echo 🧪 === TESTS FONCTIONNELS ===
echo.

echo Test de résumé V2...
curl -s -X POST http://localhost:15000/summarize_v2 ^
  -H "Content-Type: application/json" ^
  -d "{\"title\":\"Innovation IA\",\"content\":\"Nouvelle technologie révolutionnaire en intelligence artificielle.\",\"domain\":\"innovation_tech\"}"
echo.
echo.

echo 📁 === VERIFICATION DES FICHIERS ===
echo.

echo Structure des dossiers articles:
if exist "obsidian_vault\articles" (
    echo %SUCCESS% Dossier obsidian_vault\articles existe
    dir /b obsidian_vault\articles
) else (
    echo %ERROR% Dossier obsidian_vault\articles manquant
)
echo.

echo Configuration sources:
if exist "config\sources.json" (
    echo %SUCCESS% config\sources.json existe
    echo 📊 Taille: 
    dir config\sources.json | findstr sources.json
) else (
    echo %ERROR% config\sources.json manquant
)
echo.

echo 📊 === RESUME DES TESTS ===
echo.

:: Calcul du score de santé
set /a score=0
if %llm_health% equ 0 set /a score=%score%+25
if %nodered_status% equ 0 set /a score=%score%+25
if exist "obsidian_vault\articles" set /a score=%score%+25
if exist "config\sources.json" set /a score=%score%+25

echo Score de santé du pipeline: %score%/100

if %score% geq 75 (
    echo %SUCCESS% Pipeline en excellent état
) else if %score% geq 50 (
    echo %WARNING% Pipeline fonctionnel avec quelques problèmes
) else (
    echo %ERROR% Pipeline en état critique
)

echo.
echo ============================================
echo 🎯 Services sur ports élevés:
echo 🤖 LLM Service: http://localhost:15000
echo   • Health: http://localhost:15000/health
echo   • Status: http://localhost:15000/status
echo   • Classify V1: POST http://localhost:15000/classify
echo   • Classify V2: POST http://localhost:15000/classify_v2
echo   • Summarize V2: POST http://localhost:15000/summarize_v2
echo.
echo 🔧 Node-RED: http://localhost:18880
echo.
echo 📁 Articles générés: %CD%\obsidian_vault\articles\
echo 📋 Configuration: %CD%\config\sources.json
echo.
echo 🔧 Commandes utiles:
echo • docker-compose -f docker_service\docker-compose.yml logs -f
echo • docker-compose -f docker_service\docker-compose.yml ps
echo • docker-compose -f docker_service\docker-compose.yml restart llm-service
echo.
echo ============================================
pause