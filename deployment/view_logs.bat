@echo off
cd /d "%~dp0.."

echo ============================================
echo     Monitoring Logs - Pipeline Portable
echo ============================================
echo.

echo Quel type de monitoring ?
echo.
echo [1] Logs temps reel (tous services)
echo [2] Logs LLM Service uniquement
echo [3] Logs Node-RED uniquement
echo [4] Statut + logs recents
echo [5] Statut systeme complet
echo [Q] Quitter
echo.

set /p choice="Choix (1-5, Q): "

cd docker_service

if /i "%choice%"=="1" goto realtime_all
if /i "%choice%"=="2" goto realtime_llm
if /i "%choice%"=="3" goto realtime_nodered
if /i "%choice%"=="4" goto recent_logs
if /i "%choice%"=="5" goto full_status
if /i "%choice%"=="q" goto quit
goto invalid

:realtime_all
echo Logs temps reel (tous) - Ctrl+C pour arreter
timeout /t 2 /nobreak >nul
docker-compose logs -f
goto end

:realtime_llm
echo Logs LLM temps reel - Ctrl+C pour arreter
timeout /t 2 /nobreak >nul
docker-compose logs -f llm-service
goto end

:realtime_nodered
echo Logs Node-RED temps reel - Ctrl+C pour arreter
timeout /t 2 /nobreak >nul
docker-compose logs -f nodered
goto end

:recent_logs
echo Logs recents (30 dernieres lignes)
echo.
echo LLM Service:
docker-compose logs --tail=15 llm-service
echo.
echo Node-RED:
docker-compose logs --tail=15 nodered
goto end

:full_status
echo Statut systeme complet
echo.
echo Conteneurs:
docker-compose ps
echo.
echo Ressources:
docker stats --no-stream rss_llm_service rss_nodered 2>nul || echo "Stats non disponibles"
echo.
echo Connectivite:
curl -s http://localhost:15000/health && echo "LLM Health OK" || echo "LLM Health echec"
curl -s http://localhost:18880 >nul && echo "Node-RED OK" || echo "Node-RED echec"
goto end

:invalid
echo Choix invalide
timeout /t 2 /nobreak >nul
goto quit

:quit
echo Monitoring ferme
goto end

:end
echo.
echo Commandes utiles:
echo • docker-compose logs -f [SERVICE]
echo • docker-compose restart [SERVICE]
echo • docker-compose ps
echo ============================================
pause