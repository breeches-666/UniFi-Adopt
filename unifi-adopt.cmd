@echo off
chcp 65001 >nul
title UniFi Adopt - SSH Network Scanner

REM Pfad zum Skript-Ordner ermitteln
set "SCRIPTDIR=%~dp0"

REM plink.exe suchen: zuerst im Skript-Ordner, dann im PATH
set "PLINK="
if exist "%SCRIPTDIR%plink.exe" (
    set "PLINK=%SCRIPTDIR%plink.exe"
) else (
    where plink >nul 2>nul
    if not errorlevel 1 (
        set "PLINK=plink"
    )
)

if "%PLINK%"=="" (
    echo ============================================================
    echo  FEHLER: plink.exe wurde nicht gefunden!
    echo.
    echo  WICHTIG: plink.exe ist NICHT putty.exe!
    echo  plink.exe ist das Kommandozeilen-SSH-Tool von PuTTY.
    echo.
    echo  Bitte lade plink.exe herunter und lege es in den
    echo  gleichen Ordner wie dieses Skript.
    echo  Download: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
    echo ============================================================
    pause
    exit /b 1
)

echo ============================================================
echo  UniFi Adopt - SSH Network Scanner
echo ============================================================
echo.
set /p DOMAIN="Wie lautet die Domain deines UniFi Controllers? "

if "%DOMAIN%"=="" (
    echo Keine Domain eingegeben. Abbruch.
    pause
    exit /b 1
)

echo.
echo Controller-URL: http://%DOMAIN%:8080/inform
echo.

REM Lokale IP und Subnetz ermitteln
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    for /f "tokens=1-3 delims=." %%b in ("%%a") do (
        set "SUBNET=%%b.%%c.%%d"
    )
)

set "SUBNET=%SUBNET: =%"

echo Erkanntes Subnetz: %SUBNET%.0/24
echo.
echo Starte SSH-Verbindungen zu %SUBNET%.1 - %SUBNET%.254 ...
echo Befehl: set-inform http://%DOMAIN%:8080/inform
echo.

for /l %%i in (1,1,254) do (
    echo [%%i/254] Verbinde zu %SUBNET%.%%i ...
    start "" /b cmd /c "echo y | "%PLINK%" -ssh -P 22 -l ubnt -pw ubnt -batch -no-antispoof %SUBNET%.%%i "set-inform http://%DOMAIN%:8080/inform" >nul 2>nul"
)

echo.
echo ============================================================
echo  Fertig! Alle 254 SSH-Verbindungen wurden gestartet.
echo  Die Befehle laufen im Hintergrund.
echo ============================================================
pause
