@echo off
setlocal enabledelayedexpansion

:: ========================================
:: RSS + LLM Pipeline - Stop Quotidien
:: ========================================

echo.
echo ==========================================
echo 🛑 RSS + LLM Pipeline - Stop Quotidien
echo ==========================================
echo.

:: Couleurs
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set RED=[91m
set RESET=[0m

:: ========================================
:: ARRET DIRECT CONTENEURS
:: ========================================

echo %YELLOW%🛑 Arret conteneurs...%RESET%

docker stop rss_llm_service_v3 rss_nodered

if %errorlevel% equ 0 (
    echo %GREEN%✅ Conteneurs arretes%RESET%
) else (
    echo %RED%❌ Erreur arret conteneurs%RESET%
)

echo.

:: ========================================
:: VERIFICATION ETAT
:: ========================================

echo %BLUE%📊 Etat final:%RESET%
docker ps --filter "name=rss_" --format "{{.Names}} - {{.Status}}"

echo.
echo %GREEN%✅ Pipeline RSS + LLM arrete%RESET%
echo.

pause >nul
