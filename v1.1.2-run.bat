@echo off
setlocal enableextensions enabledelayedexpansion

::Local variables.
set /a check=0
set /a ckEULA=0
set /a ckRES=0
set /a sE=0

:getRet
set ret=%cd%
for /l %%i in (-1, -1, -128) do (
	echo.\/|find "!cd:~%%i,1!">nul && (set name=!cd:~%%i!&&goto :setTitle) || (echo.>nul)
)

:setTitle
set name=%name:~1%
title Server %name%

:batSettings
if not exist batch.settings (
	call :getVer
	echo version=!ver!>batch.settings
	echo.skip-UPnP=false>>batch.settings
	echo.backup-Default=No>>batch.settings
)
for %%i in (*.bat) do set runFile=%%i
for /f "tokens=*" %%v in ('find /i "version" batch.settings') do set ver=%%v
for /f "tokens=*" %%d in ('find /i "backup-Default" batch.settings') do set defBack=%%d
for /f "tokens=*" %%s in ('find /I "skip" batch.settings') do set skip=%%s
set ver=%ver:~8%
set defBack=%defBack:~15%
set skip=%skip:~10%
if "%ver%"=="" call :getVer && call :batchRefresh ver !ver!
if "%defBack%"=="" call :batchRefresh defBack No
if "%skip%"=="" call :batchRefresh skip false
goto :mapCheck

:batchRefresh
if %~1==ver (echo.version=%~2>batch.settings&&echo.skip-UPnP=!skip!>>batch.settings& echo.backup-Default=!defBack!>>batch.settings)
if %~1==skip (set skip=%~2&& echo.version=!ver!>batch.settings&& echo.skip-UPnP=%~2>>batch.settings&& echo.backup-Default=!defBack!>>batch.settings)
if %~1==defBack (set defBack=%~2&& echo.version=!ver!>batch.settings&& echo.skip-UPnP=!skip!>>batch.settings&& echo.backup-Default=%~2>>batch.settings)
exit /b 0

:mapCheck
if exist portmapper.jar goto :run

::Skips check for portmapper if set in true the batch.settings file.
if /i %skip%==true goto :run

::Changes the portmapper name for the version name to portmapper.jar.
FOR /L %%a IN (0, 1, 9) DO (
	FOR /L %%b IN (0, 1, 9) DO (
		FOR /L %%c IN (0, 1, 9) DO (
			IF EXIST portmapper-%%a.%%b.%%c.jar (
				ren %cd%\portmapper-%%a.%%b.%%c.jar portmapper.jar > nul
			)
		)
	)
)

::Checks if the portmapper is downloaded and if it isn't prompts to
::download and asks if you want to skip this check in the future.
if not exist portmapper.jar (
	echo.If You Don't Have The Port Mapper You Will Need To Port Forward Manually, The Port
	echo.Mapper Does Not Work If You Are Hosting A Network Bridge On This Host Device.
	echo.Get The UPnP Port Mapper Version 2.1.1 From https://sourceforge.net/projects/upnp-portmapper/files/v2.1.1/portmapper-2.1.1.jar
	set /p "skip=Do You Want To Skip The Portmapper Check In The Future (Y/ N): "||set skip=%skip%
	echo.yes|find /i "!skip!">nul && (
		call :batchRefresh skip true
	) || (
		call :batchRefresh skip false
	)
	echo.This Can Be Changed In The batch.settings File To Re-enable This Check. && timeout 5 /nobreak>nul
)

:run
if not exist !ver!-server.jar (call :buildServer %ver%)
if %ckEULA%==3 (call :error eula_Set , 0xD8 , false)
if %ckRES%==3 (call :error restart_Set , 0xD9 , false)
call :getIP
call :ramFind
cls
echo.Join Externally Using %extIP%:%port%
echo.Or Internally Using %intIP%:%port%
echo.
echo.RAM=%ram%B
echo.

::Starts the UPnP port forwarding if portmapper is downloaded.
if exist portmapper.jar (
	java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol tcp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft_TCP > nul & java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol udp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft_UDP > nul || call :error port_Set , 0x2E , FAIL
)

::This is the actual server start.
java -Xmx%ram% -jar !ver!-server.jar nogui ||call :error server_Start , 0xD4 , FAIL

::Ends the UPnP port forwarding if portmapper is downloaded.
if exist portmapper.jar (
	java -jar portmapper.jar -delete -externalPort %port% -protocol tcp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory > nul & java -jar portmapper.jar -delete -externalPort %port% -protocol udp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory > nul || call :error port_Del , 0x29 , FAIL
)

::This runs a number of post-checks for certain criteria.
find /i "agree to the EULA" logs\latest.log>nul && (set /a ckEULA=%ckEULA%+1&&set /a sE=!sE!+1&&echo.&&echo.Use This Time To Edit The Server Properties To How You Wish.&& pause>nul|echo.Press Any Key To Retry...&&goto :run)
find /i "Startup script" logs\latest.log>nul && (cls&&set /a ckRES=!ckRES!+1&&set /a sE=!sE!+1&&echo.&& echo.In Order For The Restart Command To Work You Must Edit Spigot.yml Line 24 From "restart-script: ./start.sh" to "restart-script: %runFile%".&&pause>nul|echo.Press Any Key To Restart...&& goto :run)
find /i "Attempting to restart" logs\latest.log>nul && (goto :end)

set /p backup=Do You Want To Backup Your Server (Y/ N): ||set backup=%defBack%
call :batchRefresh defBack %backup%
call :error ending
echo.yes|find /i "%backup%">nul&&(goto :backup)||(goto :end)

:backup
if /i "%defBack%"=="No" (echo.Default Backup Setting Can Be Changed In The batch.settings File.)
xcopy /S /Q /Y /F /I "..\%name%" "%userprofile%\Desktop\Server_Backups\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%" || call :error backup_Comp , 0x4D , FAIL
echo.Your Server Has Been Backed Up To %userprofile%\Desktop\Server_Backups\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%.
pause&&goto :end

:log
for /l %%i in (1,1,100) do (
	rem if exist "logs\%date:~-4%-%date:~3,2%-%date:~0,2%-%%i.log.gz" (del logs\%date:~-4%-%date:~3,2%-%date:~0,2%-%%i.log.gz)
	if not exist "logs\%date:~-4%-%date:~3,2%-%date:~0,2%-%%i-error.log" (ren logs\latest.log %date:~-4%-%date:~3,2%-%date:~0,2%-%%i-error.log&&goto :end)||call :error log_REN , 0x03 , rename_FAIL
	if %%i==100 (call :error log_Cap , 0x0B , %%i)
)

:getVer
cls
for /l %%i in (260,-1,0) do (echo.0123456789|find /i "!cd:~%%i,1!">nul&&set /a start=%%i&&break)
for /l %%i in (0,1,260) do (echo.0123456789|find /i "!cd:~%%i,1!">nul&&set /a end=%%i&&break)
set /a "len=%end%-%start%+1"
set ver=!cd:~%start%,%len%!
for /l %%i in (0, 1, !len!) do (echo.abcdefghijklmnopqrstuvwxyz-_~\/,() |find /i "!ver:~%%i,1!">nul&&call :error invalid_Version , 0x72 , "ver=!ver!")
exit /b 0

:buildServer
if %check% == 3 (call :error build_Error , 0x8E , "build_Attempts=%check%")
echo.Version=%~1
set "buildLoc=..\..\BuildTools"
if not exist ..\..\BuildTools\spigot-%~1.jar (
	set "buildLoc=..\BuildTools"
	if not exist ..\BuildTools\spigot-%~1.jar (
		if not exist ..\BuildTools (
			if exist ..\..\BuildTools (set "buildLoc=..\..\BuildTools") else (set "buildLoc=..\BuildTools"&&mkdir !buildLoc!||call :error build_Error , 0x83 , mkdir_FAIL)
		)
		cd !buildLoc!
		echo !cd!
		curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar ||call :error build_Error , 0x89 , buildTool_FAIL
		cls
		java -Xmx2G -jar BuildTools.jar --rev %~1 ||call :error build_Error , 0x87 , no_BuildTool
		cd %ret%
		cls
	)
)
echo.F|xcopy /S /Q /Y /F "%buildLoc%\spigot-%ver%.jar" "!ver!-server.jar">nul||call :error build_Error , 0x8C , copy_FAIL
if not exist !ver!-server.jar (set /a check=%check%+1 && goto :buildServer) else (exit /b 0)

:getIP
for /f "tokens=*" %%i in ('curl -s ip-adresim.app -4') do set extIP=%%i
for /f "tokens=1-2 delims=:" %%a in ('ipconfig^|find "IPv4"') do set intIP=%%b
set intIP=%intIP:~1%
call :portFind
exit /b 0

:portFind
cls
if not exist server.properties (echo.>server.properties)
find /I "server-port" server.properties>nul
if Errorlevel 1 (call :portSet && exit /b 0) Else (call :portCheck && exit /b 0)

:portSet
set /p por=Please Select An IP Port For The Server (Default 25565): ||set por=25565
echo.server-port=%por%>>server.properties
call :portCheck
exit /b 0

:portCheck
for /f "tokens=*" %%p in ('find /I "server-port" server.properties') do set port=%%p
set port=%port:~12%
set pt=%port%
if "%port%"=="" (call :portSet)
for /l %%i in (0,1,4) do (
	echo.0123456789|find /i "!port:~%%i,1!">nul&&(echo.>nul)||(call :error invalid_Port , 0xF9 , %pt%)
)
if %port% gtr 65535 (call :error invalid_Port , 0xF3 , %pt%)
exit /b 0

:ramFind
cls
if not exist server.properties (echo.>server.properties)
find /I "ram" server.properties>nul
if ErrorLevel 1 (call :ramSet && exit /b 0) Else (call :ramCheck && exit /b 0)

:ramSet
set /p ram=Input Max RAM Access For Server (Default 2GB): ||set ram=2G
if /i "%ram:~-1%"=="B" (set ram=!ram:~0,-1!)
echo.ram=%ram%>>server.properties
call :ramCheck
exit /b 0

:ramCheck
for /f "tokens=*" %%g in ('find /I "ram" server.properties') do set ram=%%g
set ram=%ram:~4%
set rm=%ram%
if "%ram%"=="" (call :ramSet)
if /i "%ram:~-1%"=="B" (set ram=!ram:~0,-1!|| call :error invalid_RAM , 0x52 , %rm% )
if /i "%ram:~-1%"=="B" (call :error invalid_RAM , 0x52 , %rm% )
if "%ram:~-1%" neq "G" (
	if %ram:~0,-1% lss 512 (
		call :error invalid_RAM , 0x5A , %rm%
	)
)
exit /b 0

:error
cls
if %~1==ending (
	echo.[%time:~0,-3%] Server.Backup: !backup! >>logs\latest.log
	echo.[%time:~0,-3%] Server.Name: !name! >>logs\latest.log
	echo.[%time:~0,-3%] Server.Errors: !sE! >>logs\latest.log
	exit /b 0
)
echo.Error: %~2 &&echo.[%time:~0,-3%] System.Error: %~2 >>logs\latest.log
echo.Descriptor: %~1 &&echo.[%time:~0,-3%] System.Descriptor: %~1 >>logs\latest.log
echo.Value: %~3 &&echo.[%time:~0,-3%] System.Value: %~3 >>logs\latest.log
pause
call :log

:end
echo.Stopping
exit

endlocal