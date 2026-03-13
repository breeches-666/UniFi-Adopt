@echo off
chcp 65001 >nul
title UniFi Adopt - SSH Network Scanner

REM Pfad zum Skript-Ordner ermitteln
set "SCRIPTDIR=%~dp0"

REM plink.exe suchen: zuerst im Skript-Ordner, dann im PATH
if exist "%SCRIPTDIR%plink.exe" set "PLINK=%SCRIPTDIR%plink.exe" & goto :found
where plink >nul 2>nul
if not errorlevel 1 set "PLINK=plink" & goto :found

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

:found
REM plink via PATH verfuegbar machen (vermeidet Quoting-Probleme bei Pfaden mit Leerzeichen)
set "PATH=%SCRIPTDIR%;%PATH%"

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

REM Hilfs-Skript erstellen (eigener Prozess = saubere Pipe fuer echo y)
set "HELPER=%TEMP%\unifi-adopt-helper.cmd"
echo @echo off > "%HELPER%"
echo echo y ^| plink -ssh -P 22 -l ubnt -pw ubnt %%1 mca-cli-op set-inform http://%%2:8080/inform >> "%HELPER%"

for /l %%i in (1,1,254) do (
    echo [%%i/254] Verbinde zu %SUBNET%.%%i ...
    start /min "" cmd /c ""%HELPER%" %SUBNET%.%%i %DOMAIN%"
)

echo.
echo ============================================================
echo  Fertig! Alle 254 SSH-Verbindungen wurden gestartet.
echo  Die Fenster schliessen sich automatisch nach Abschluss.
echo ============================================================
pause
del "%HELPER%" 2>nul
