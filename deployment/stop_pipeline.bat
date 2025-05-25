@echo off
cd /d "%~dp0.."

echo ============================================
echo      Arret Pipeline RSS + LLM - Portable
echo ============================================
echo.

echo Que souhaitez-vous faire ?
echo.
echo [1] Arret simple
echo [2] Arret + suppression donnees temporaires
echo [3] Arret + nettoyage Docker complet
echo [4] Redemarrage rapide
echo [Q] Annuler
echo.

set /p choice="Choix (1-4, Q): "

cd docker_service

if /i "%choice%"=="1" goto simple
if /i "%choice%"=="2" goto clean_temp
if /i "%choice%"=="3" goto full_clean
if /i "%choice%"=="4" goto restart
if /i "%choice%"=="q" goto cancel
goto invalid

:simple
echo Arret services...
docker-compose down
echo Services arretes
goto end

:clean_temp
echo Arret + nettoyage donnees temporaires...
echo Les donnees Node-RED seront perdues !
echo Continuer ? (y/N)
set /p confirm="Reponse: "
if /i not "%confirm%"=="y" goto cancel
docker-compose down -v
echo Arret + nettoyage termine
goto end

:full_clean
echo Nettoyage complet Docker...
echo Toutes les images Docker inutiles seront supprimees !
echo Continuer ? (y/N)
set /p confirm="Reponse: "
if /i not "%confirm%"=="y" goto cancel
docker-compose down -v
docker system prune -f
echo Nettoyage complet termine
goto end

:restart
echo Redemarrage rapide...
docker-compose down
timeout /t 3 /nobreak >nul
docker-compose up -d
echo Redemarrage en cours...
timeout /t 15 /nobreak >nul
curl -s http://localhost:15000/health >nul && echo LLM OK || echo LLM demarrage...
curl -s http://localhost:18880 >nul && echo Node-RED OK || echo Node-RED demarrage...
goto end

:invalid
echo Choix invalide
goto cancel

:cancel
echo Operation annulee
goto end

:end
echo.
echo Statut actuel:
docker-compose ps 2>nul || echo Aucun service actif
echo.
echo Utilitaires:
echo • Demarrer: deployment\start_pipeline.bat
echo • Tester: deployment\test_pipeline.bat
echo ============================================
pause