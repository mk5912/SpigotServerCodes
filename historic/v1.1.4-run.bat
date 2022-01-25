::Version: 1.1.4
@echo off
setlocal enableextensions enabledelayedexpansion

set ckBUILD=0
set ckEULA=0
set ckRES=0
set sE=0
set m=512
set /a k=%m%*1024
set /a b=%k%*1024
set charList=abcdefghijklmnopqrstuvwxyz\/,;'~#[]{}!£$%^&*()|:@_+¬` 

:getDir
set ret=%cd%
for /l %%i in (-1, -1, -128) do (echo.\/|find "!cd:~%%i,1!">nul&&((set name=!cd:~%%i!&&goto :setTitle)||call :error dir_Check 0xA2 fetch_FAIL))

:setTitle
set name=%name:~1%
title Server %name%

:run
call :batSettings
call :mapCheck
if not exist !ver!-server.jar (call :buildServer %ver%)
if %ckEULA%==3 (call :error eula_Set 0xD8 false)
if %ckRES%==3 (call :error restart_Set 0xD9 false)
cls
echo.Join Externally Using %extIP%:%port%
echo.Or Internally Using %intIP%:%port%
echo.
echo.Version=%ver%
echo.RAM=%ram%B
echo.
if exist portmapper.jar (
	java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol tcp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft_TCP>nul&java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol udp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft_UDP>nul||call :error port_Set 0x2E FAIL
)
java -Xmx%ram% -jar !ver!-server.jar nogui||call :error server_Start 0xD4 FAIL
if exist portmapper.jar (
	java -jar portmapper.jar -delete -externalPort %port% -protocol tcp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory>nul&java -jar portmapper.jar -delete -externalPort %port% -protocol udp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory>nul||call :error port_Del 0x29 FAIL
)

:preCheck
find /i "agree to the EULA" logs\latest.log>nul&&(set /a ckEULA=%ckEULA%+1&&set /a sE=!sE!+1&&echo.&&echo.Use This Time To Edit The Server Properties To How You Wish.&&pause>nul|echo.Press Any Key To Retry...&&goto :run)
find /i "Startup script" logs\latest.log>nul&&(cls&&set /a ckRES=!ckRES!+1&&set /a sE=!sE!+1&&echo.&&echo.In Order For The Restart Command To Work You Must Edit Spigot.yml "restart-script: ./start.sh" to "restart-script: %runFile%".&&pause>nul|echo.Press Any Key To Restart...&&goto :run)
find /i "Attempting to restart" logs\latest.log>nul&&(goto :end)
set /p backup=Do You Want To Backup Your Server (Y/ N): ||set backup=%defBack%
call :error ending
echo.yes|find /i "%backup%">nul&&(goto :backup)||(goto :end)

:backup
xcopy /S /Q /Y /F /I "..\%name%" "%locBack%\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%"||call :error backup_Comp 0x4D FAIL
echo.Your Server Has Been Backed Up To %locBack%\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%.
pause&&goto :end

:log
for /l %%i in (1,1,100) do (
	if not exist "logs\%date:~-4%-%date:~3,2%-%date:~0,2%-%%i-error.log" (ren logs\latest.log %date:~-4%-%date:~3,2%-%date:~0,2%-%%i-error.log&&goto :end)||call :error log_Error 0x03 rename_FAIL
	if %%i==100 (call :error log_Error 0x0B %%i)
)

:getVer
cls
echo.Attempting To Find Version.
for /l %%i in (260,-1,0) do (echo.0123456789|find /i "!cd:~%%i,1!">nul&&set /a start=%%i&&break)
for /l %%i in (0,1,260) do (echo.0123456789|find /i "!cd:~%%i,1!">nul&&set /a end=%%i&&break)
set /a "len=%end%-%start%+1"
set ver=!cd:~%start%,%len%!
cls
if "%end%"=="" set /p ver=No Version Found, Please Input A Valid Version: ||set /a sE=!sE!+1&&call :getVer
for /l %%i in (0, 1, !len!) do echo.!charList!|find /i "!ver:~%%i,1!">nul&&(cls&&set /p ver=No Valid Version Found, Please Input A Valid Version: ||call :error invalid_Version 0x72 no_VERSION)
exit /b 0

:buildServer
if %ckBUILD% == 3 (call :error build_Error 0x8E, "build_Attempts=%ckBUILD%")
echo.Version=%~1
set "buildLoc=..\..\BuildTools"
if not exist !buildLoc!\spigot-%~1.jar (
	set "buildLoc=..\BuildTools"
	if not exist !buildLoc!\spigot-%~1.jar (
		if not exist !buildLoc! (
			if exist ..\!buildLoc! (set "buildLoc=..\..\BuildTools") else (set "buildLoc=..\BuildTools"&&mkdir !buildLoc!||call :error build_Error 0x83 mkdir_FAIL)
		)
		cd !buildLoc!
		curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar ||call :error build_Error 0x89 no_BuildTool
		cls
		java -Xmx2G -jar BuildTools.jar --rev %~1 ||call :error build_Error 0x87 buildTool_FAIL
		cd !ret!
		cls
	)
)
echo.F|xcopy /S /Q /Y /F "%buildLoc%\spigot-%ver%.jar" "!ver!-server.jar">nul||call :error build_Error 0x8C copy_FAIL
if not exist !ver!-server.jar (set /a ckBUILD=%ckBUILD%+1&&goto :buildServer) else (exit /b 0)

:getIP
for /f "tokens=*" %%i in ('curl -s ip-adresim.app -4') do (set extIP=%%i||call :error ext_IP 0xF5, fetch_FAIL)
for /f "tokens=1-2 delims=:" %%a in ('ipconfig^|find "IPv4"') do (set intIP=%%b&&set intIP=!intIP:~1!||call :error int_IP 0xF6 fetch_FAIL)
exit /b 0

:portDef
cls
for /f "tokens=*" %%p in ('find /I "server-port" server.properties') do set port=%%p
set port=%port:~12%
if "%port%" equ "" (set /p "port=Please Select An IP Port For The Server (Default 25565): "||set port=25565)&&echo.server-port=!port!>>server.properties||call :error invalid_Port 0xFD save_FAIL
for /l %%i in (0,1,4) do (echo.!charList!.|find /i "!port:~%%i,1!">nul&&(call :error invalid_Port 0xF9 %port%))
if %port% lss 10000 (call :error invalid_Port 0xF3 %port%)
if %port% gtr 65535 (call :error invalid_Port 0xF3 %port%)
exit /b 0

:ram
cls
if "%~1"=="set" (set /p "ram=Input Max RAM Access For Server (Default 2GB): "||set ram=2G)
for /l %%i in (1,1,12) do (echo.GMKB|find /i "!ram:~%%i,1!">nul&&(set "ram=!ram:~0,%%i!!ram:~%%i,1!"&&break))
if "%ram:~-1%" equ "B" (if %ram:~0,-1% lss %b% (call :error invalid_RAM 0x5A %ram%))
if /i "%ram:~-1%" equ "B" (set ram=!ram:~0,-1!)
if "%ram:~-1%" equ "K" (if %ram:~0,-1% lss %k% (call :error invalid_RAM 0x5A %ram%))
if "%ram:~-1%" equ "M" (if %ram:~0,-1% lss %m% (call :error invalid_RAM 0x5A %ram%))
exit /b 0

:batSettings
call :portDef
if not exist batch.settings (
	call :getVer
	call :ram set
	echo version=!ver!>batch.settings
	echo.skip-UPnP=false>>batch.settings
	echo.ram=!ram!>>batch.settings
	echo.backup-Default=No>>batch.settings
	echo.backup-Location=!userprofile!\Desktop\Server_Backups>>batch.settings
)
call :getIP
for %%i in (*.bat) do set runFile=%%i
for /f "tokens=*" %%v in ('find /i "version" batch.settings') do set ver=%%v
for /f "tokens=*" %%s in ('find /i "skip" batch.settings') do set skip=%%s
for /f "tokens=*" %%r in ('find /i "ram" batch.settings') do set ram=%%r||set "ram="
for /f "tokens=*" %%d in ('find /i "backup-Default" batch.settings') do set defBack=%%d
for /f "tokens=*" %%l in ('find /i "backup-Location" batch.settings') do set locBack=%%l
set ver=%ver:~8%
set skip=%skip:~10%
set ram=%ram:~4%
call :ram
set defBack=%defBack:~15%
set locBack=%locBack:~16%
if "%ver%"=="" call :getVer&&call :batchRefresh ver !ver!
if "%skip%"=="" call :batchRefresh skip false
if "%ram%"=="" call :ram set&&call :batchRefresh ram !ram!
if "%defBack%"=="" call :batchRefresh defBack No
if "%locBack%"=="" call :batchRefresh locBack !userprofile!\Desktop\Server_Backups
exit /b 0

:batchRefresh
set "%~1=%~2"&& echo.version=!ver!>batch.settings&&echo.skip-UPnP=!skip!>>batch.settings&&echo.ram=!ram!>>batch.settings&&echo.backup-Default=!defBack!>>batch.settings&&echo.backup-Location=!locBack!>>batch.settings
exit /b 0

:mapCheck
if exist portmapper.jar exit /b 0
if /i %skip%==true exit /b 0
FOR /L %%a IN (0, 1, 9) DO (
	FOR /L %%b IN (0, 1, 9) DO (
		FOR /L %%c IN (0, 1, 9) DO (
			IF EXIST portmapper-%%a.%%b.%%c.jar (
				ren %cd%\portmapper-%%a.%%b.%%c.jar portmapper.jar>nul&&break
			)
		)
	)
)
if not exist portmapper.jar (
	echo.If You Don't Have The Port Mapper You Will Need To Port Forward Manually, The Port
	echo.Mapper Does Not Work If You Are Hosting A Network Bridge On This Host Device.
	echo.Get The UPnP Port Mapper Version 2.1.1 From https://sourceforge.net/projects/upnp-portmapper/files/v2.1.1/portmapper-2.1.1.jar
	set /p "skip=Do You Want To Skip The Portmapper Check In The Future (Y/ N): "||set skip=%skip%
	echo.yes|find /i "!skip!">nul&&(
		call :batchRefresh skip true
	)||(
		call :batchRefresh skip false
	)
	echo.This Can Be Changed In The batch.settings File To Re-enable This Check.&&timeout 5 /nobreak>nul
)
exit /b 0

:error
cls
if %~1==ending (
	echo.[%time:~0,-3%] Server.Backup: !backup!>>logs\latest.log
	echo.[%time:~0,-3%] Server.Name: !name!>>logs\latest.log
	echo.[%time:~0,-3%] Server.Errors: !sE!>>logs\latest.log
	exit /b 0
)
set /a sE=%sE%+1
echo.Error: %~2&&echo.[%time:~0,-3%] System.Error: %~2>>logs\latest.log
echo.Tag: %~1&&echo.[%time:~0,-3%] System.Tag: %~1>>logs\latest.log
echo.Value: %~3&&echo.[%time:~0,-3%] System.Value: %~3>>logs\latest.log
if exist error-Codes.txt (
	for /f "tokens=*" %%e in ('find /i "%~2" error-Codes.txt') do set des=%%e
	set des=!des:~7!
	if "%des%"neq"" (echo.Description: !des!&&echo.[!time:~0,-3!] System.Description: !des!>>logs\latest.log)
)
pause
if %~1==log_Error goto :end
goto :log

:end
echo.Stopping.
endlocal
exit