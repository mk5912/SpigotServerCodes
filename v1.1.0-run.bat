@echo off
setlocal enableextensions enabledelayedexpansion

:getVer
echo._/\abcdefghijklmnopqrstuvwxyz- |find /i "%cd:~-8,1%" > nul && (
	echo._/\abcdefghijklmnopqrstuvwxyz- |find /i "%cd:~-7,1%" > nul && (set ver=%cd:~-6%) || (set ver=%cd:~-7%)
) || (set ver=%cd:~-8%)

:setTitle
title Release %ver% Server

:getReturn
set ret=%cd%
for /l %%i in (-1, -1, -50) do (
	echo.\/|find "!cd:~%%i,1!">nul && (set name=!cd:~%%i!) || (echo.>nul)
)

:porterCheck
if not exist batch.settings (
	echo.skip-porter=false>batch.settings
)

for /f "tokens=*" %%s in ('find /I "skip" batch.settings') do set skip=%%s
set skip=%skip:~12%
echo Port-mapper-bypas=%skip%

if /i %skip%==true (goto :serverCheck)

FOR /L %%a IN (0, 1, 9) DO (
	FOR /L %%b IN (0, 1, 9) DO (
		FOR /L %%c IN (0, 1, 9) DO (
			IF EXIST portmapper-%%a.%%b.%%c.jar (
				ren %cd%\portmapper-%%a.%%b.%%c.jar portmapper.jar > nul
			)
		)
	)
)

if not exist portmapper.jar (
	pause>nul|echo Please download the UPnP port mapper version 2.1.1 from https://sourceforge.net/projects/upnp-portmapper/files/v2.1.1/portmapper-2.1.1.jar
	set /p "skip=Do you wish to skip the portmapper check in future (Y/ N): "||set skip=yes
	echo yes|find /i "!skip!">nul && (
		echo.skip-porter=true>batch.settings
	) || (
		echo.skip-porter=false>batch.settings
	)
	echo.This can be changed in the batch.settings file to re-enable this check. && timeout 5 /nobreak>nul
)

if exist portmapper.jar (
	if "%skip%"=="false" (
		echo.skip-porter=true>batch.settings
	)
)

:serverCheck
if not exist server.jar (
	echo Version=%ver%
	if not exist ..\BuildTools\spigot-%ver%.jar (
		if not exist ..\BuildTools (
			mkdir ..\BuildTools
		)
		cd ..\\BuildTools
		curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
		java -Xmx2G -jar BuildTools.jar --rev %ver%
		cd %ret%
		cls
  )
  echo.F|xcopy /S /Q /Y /F "..\BuildTools\spigot-%ver%.jar" "server.jar">nul
)

find /I "ram" server.properties>nul
if ErrorLevel 1 (goto :ramSet) Else (goto :ramCheck)

:ramSet
cls
set /p val=Input max RAM access for server (default 2GB): ||set val=2G
echo.ram=%val%>>server.properties

:ramCheck
for /f "tokens=*" %%g in ('find /I "ram" server.properties') do set ram=%%g
set ram=%ram:~4%

find /I "server-port" server.properties>nul
if ErrorLevel 1 (goto :portSet) Else (goto :portCheck)

:portSet
set /p por=Please select an IP port for the server (default 25565): ||set por=25565
echo.server-port=%por%>>server.properties

:portCheck
for /f "tokens=*" %%p in ('find /I "server-port" server.properties') do set port=%%p
set port=%port:~12%

:run
if not exist server.jar (goto :progCheck)
if %ram:~0,-1% lss 512 (
	if "%ram:~-1%" neq "G" (
		set ram=512M
		echo ram=512M>server.properties
		echo server-port=%port%>>server.properties
	)
)
cls
echo.Running on IP Port %port%
echo.RAM=%ram%B
if exist portmapper.jar (
	java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol tcp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft > nul & java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol udp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft > nul
)
java -Xmx%ram% -jar server.jar nogui
find /i "agree to the EULA" logs\latest.log>nul && (echo: && echo.Use this time to edit the server properties to how you wish. && pause > nul|echo.Press any key to retry... && goto :run)
if exist portmapper.jar (
	java -jar portmapper.jar -delete -externalPort %port% -protocol tcp > nul & java -jar portmapper.jar -delete -externalPort %port% -protocol udp > nul
)
set /p backup=Do you want to backup your server (Y/ N): ||set backup=N

echo yes|find /i "%backup%"&&(goto :backup)||(goto :end)

:error
echo.An error has occured
pause
goto :end

:backup
robocopy /s "..\%name%" "%userprofile%\Desktop\Server_Backups\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%"

:end
echo.Stopping
endlocal