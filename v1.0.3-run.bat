::Version: 1.0.3
@echo off
setlocal enableextensions enabledelayedexpansion

:getReturn
set ret=%cd%

:getVer
echo._/\abcdefghijklmnopqrstuvwxyz |find /i "%cd:~-8,1%" > nul && (
	echo._/\abcdefghijklmnopqrstuvwxyz |find /i "%cd:~-7,1%" > nul && (set ver=%cd:~-6%) || (set ver=%cd:~-7%)
) || (set ver=%cd:~-8%)

rem set ver=%cd:~-6%
echo Version=%ver%
rem pause

:getIP
for /f "delims=" %%a in ('ipconfig^|find /i "ipv4"') do set ip=%%b

:setTitle
title Release %ver% Server

goto :progCheck
:porter
if not exist portmapper-2.1.1.jar (
	curl -z portmapper-2.1.1.jar -o portmapper-2.1.1.jar https://downloads.sourceforge.net/project/upnp-portmapper/v2.1.1/portmapper-2.1.1.jar?ts=gAAAAABgfJAcKdbOxo4b0VMO1RXXT1YKoZHjIR1aiY8-8LbOPUjkhnEWxoxZm3dVI3-GRAKBBhmHaWp1CEJDuZe_tfZC1pyCoQ%3D%3D&r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fupnp-portmapper%2Ffiles%2Fv2.1.1%2Fportmapper-2.1.1.jar%2Fdownload
)

:progCheck
if not exist server.jar (
  if not exist ..\BuildTools\spigot-%ver%.jar (
	if not exist ..\BuildTools (
		mkdir ..\BuildTools
	)
    cd ..\\BuildTools
	curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
    java -Xmx2G -jar BuildTools.jar --rev %ver%
	cd %ret%
	echo.F|xcopy /S /Q /Y /F "..\BuildTools\spigot-%ver%.jar" "server.jar">nul
	cls
  )
  echo.F|xcopy /S /Q /Y /F "..\BuildTools\spigot-%ver%.jar" "server.jar">nul
)

:start
find /I "ram" server.properties>nul
if ErrorLevel 1 (goto :ramSet) Else (goto :ramCheck)

:ramSet
cls
set /p val=Input max RAM access for server: ||set val=2G
set /p por=Please select an IP port for the server: ||set por=25565
echo.server-port=%por%>>server.properties
echo.ram=%val%>>server.properties

:ramCheck
for /f "tokens=*" %%g in ('find /I "ram" server.properties') do set ram=%%g
set ram=%ram:~4%

:getPort
for /f "tokens=*" %%p in ('find /I "server-port" server.properties') do set port=%%p
set port=%port:~12%

rem start cmd /c "title Port Enable && echo.Attempting Port Forwarding Setup && timeout 20 /nobreak>nul && java "-Dportmapper.locationUrl=<mc.myeasyserver.xyz:8080>" -jar portmapper-2.1.1.jar -add -externalPort %port% -internalPort %port% -ip %ip% -protocol tcp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory"

:run
if not exist server.jar (goto :progCheck)
cls
echo.Running on IP Port %port%
echo.RAM=%ram%B
java -Xmx%ram% -jar server.jar nogui
find /i "agree to the EULA" logs\latest.log>nul && (pause && goto :run)
set /p backup=Do you want to backup your server (Y/ N): ||set backup=N
if /i "%backup%"=="y" (
	goto :backup
) else (
	goto :end
)

:error
echo.An error has occured
pause
goto :end

:backup
robocopy /s "..\%ver%" "%userprofile%\Desktop\Server_Backups\%ver%_Backup_%date:~8,2%\%date:~3,2%\%date:~0,2%"

:end
echo.Stopping
endlocal