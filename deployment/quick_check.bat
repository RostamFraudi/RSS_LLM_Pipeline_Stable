@echo off
cd /d "%~dp0.."

echo ============================================
echo   Quick Check - Portabilite (Safe)
echo ============================================
echo.
echo Repertoire: %CD%
echo.

echo === VERIFICATION FICHIERS ===
echo.

echo [1] Fichiers critiques:
if exist "docker_service\docker-compose.yml" (
    echo   docker-compose.yml - TROUVE
) else (
    echo   docker-compose.yml - MANQUANT
)

if exist "config\sources.json" (
    echo   sources.json - TROUVE
) else (
    echo   sources.json - MANQUANT
)

if exist "docker_service\llm_service\app.py" (
    echo   app.py - TROUVE
) else (
    echo   app.py - MANQUANT
)

if exist "docker_service\scripts\moc_generator.py" (
    echo   moc_generator.py - TROUVE
) else (
    echo   moc_generator.py - MANQUANT
)

echo.
echo === TEST PORTABILITE ===
echo.

echo [2] docker-compose.yml:
if exist "docker_service\docker-compose.yml" (
    echo   Test chemins absolus...
    type docker_service\docker-compose.yml | find "C:" >nul 2>&1
    if errorlevel 1 (
        echo   OK - Pas de chemins absolus
    ) else (
        echo   PROBLEME - Chemins absolus detectes
    )
) else (
    echo   SKIP - Fichier manquant
)

echo.
echo [3] moc_generator.py:
if exist "docker_service\scripts\moc_generator.py" (
    echo   Test chemins hardcodes...
    type docker_service\scripts\moc_generator.py | find "/obsidian_vault" >nul 2>&1
    if errorlevel 1 (
        echo   OK - Chemins portables
    ) else (
        echo   PROBLEME - Chemins hardcodes
    )
) else (
    echo   SKIP - Fichier manquant (normal si pas encore cree)
)

echo.
echo === RESUME ===
echo.

echo Status du projet:
set problems=0

REM Test docker-compose
if exist "docker_service\docker-compose.yml" (
    type docker_service\docker-compose.yml | find "C:" >nul 2>&1
    if not errorlevel 1 set problems=1
)

REM Test moc_generator seulement s'il existe
if exist "docker_service\scripts\moc_generator.py" (
    type docker_service\scripts\moc_generator.py | find "/obsidian_vault" >nul 2>&1
    if not errorlevel 1 set problems=1
)

if %problems% equ 0 (
    echo RESULTAT: Projet portable - Aucun probleme detecte
    echo.
    echo Actions suivantes:
    echo 1. deployment\start_pipeline.bat
    echo 2. deployment\test_pipeline.bat
) else (
    echo RESULTAT: Corrections necessaires
    echo.
    echo Fichiers a corriger:
    if exist "docker_service\docker-compose.yml" (
        type docker_service\docker-compose.yml | find "C:" >nul 2>&1
        if not errorlevel 1 echo - docker-compose.yml
    )
    if exist "docker_service\scripts\moc_generator.py" (
        type docker_service\scripts\moc_generator.py | find "/obsidian_vault" >nul 2>&1
        if not errorlevel 1 echo - moc_generator.py
    )
)

echo.
echo ============================================
echo Test termine - Appuyez sur une touche
pause >nul