@echo off
chcp 65001 >nul
title UniFi Adopt - SSH Network Scanner

:: Prüfe ob plink verfügbar ist
where plink >nul 2>nul
if %errorlevel% neq 0 (
    echo ============================================================
    echo  FEHLER: plink.exe wurde nicht gefunden!
    echo.
    echo  Bitte installiere PuTTY oder lege plink.exe in den
    echo  gleichen Ordner wie dieses Skript.
    echo  Download: https://www.chiark.greenend.org.uk/~sgtatham/putty/
    echo ============================================================
    pause
    exit /b 1
)

:: Domain abfragen
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

:: Lokale IP und Subnetz ermitteln
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    for /f "tokens=1-3 delims=." %%b in ("%%a") do (
        set "SUBNET=%%b.%%c.%%d"
    )
)

:: Leerzeichen am Anfang des Subnetzes entfernen
set "SUBNET=%SUBNET: =%"

echo Erkanntes Subnetz: %SUBNET%.0/24
echo.
echo Starte SSH-Verbindungen zu %SUBNET%.1 - %SUBNET%.254 ...
echo Befehl: set-inform http://%DOMAIN%:8080/inform
echo.

:: Für jede IP im Subnetz den SSH-Befehl im Hintergrund starten
for /l %%i in (1,1,254) do (
    echo [%%i/254] Verbinde zu %SUBNET%.%%i ...
    start "" /b cmd /c "echo y | plink -ssh -P 22 -l ubnt -pw ubnt -batch -no-antispoof %SUBNET%.%%i "set-inform http://%DOMAIN%:8080/inform" >nul 2>nul"
)

echo.
echo ============================================================
echo  Fertig! Alle 254 SSH-Verbindungen wurden gestartet.
echo  Die Befehle laufen im Hintergrund.
echo ============================================================
pause
