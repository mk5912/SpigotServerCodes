::Version: 1.1.5
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
for /l %%i in (-1, -1, -128) do (echo.\/|find "!cd:~%%i,1!">nul&&(goto :setTitle)||(set name=!cd:~%%i!||call :error dir_Check 0xA2 fetch_FAIL))

:setTitle
title Server %name%

:run
call :batSettings
call :mapCheck
if not exist !ver!-server.jar (call :buildServer)
if %ckEULA%==3 (call :error eula_Set 0xD8 false)
if %ckRES%==3 (call :error restart_Set 0xD9 false)
cls
echo.Join Externally Using !address!*[:!port!*]
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

:postCheck
find /i "agree to the EULA" logs\latest.log>nul&&(set /a ckEULA=%ckEULA%+1&&set /a sE=!sE!+1&&echo.&&echo.Use This Time To Edit The Server Properties To How You Wish.&&pause>nul|echo.Press Any Key To Retry...&&goto :run)
find /i "Startup script" logs\latest.log>nul&&(cls&&set /a ckRES=!ckRES!+1&&set /a sE=!sE!+1&&echo.&&echo.In Order For The Restart Command To Work You Must Edit Spigot.yml And Change "!rstart!" to "restart-script: %runFile%".&&pause>nul|echo.Press Any Key To Restart...&&goto :run)
find /i "Attempting to restart" logs\latest.log>nul&&(goto :end)
set /p backup=Do You Want To Backup Your Server (Y/ N): ||set backup=%backDef%
call :error ending
echo.yes|find /i "%backup%">nul&&(goto :backup)||(goto :end)

:backup
xcopy /S /Q /Y /F /I "..\%name%" "%backLoc%\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%"||call :error backup_Comp 0x4D FAIL
echo.Your Server Has Been Backed Up To %backLoc%\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%.
pause&&goto :end

:getVer
cls
echo.Attempting To Find Version.
for /l %%i in (260,-1,0) do (echo.0123456789|find /i "!cd:~%%i,1!">nul&&set /a start=%%i)
for /l %%i in (0,1,260) do (echo.0123456789|find /i "!cd:~%%i,1!">nul&&set /a end=%%i)
set /a "len=%end%-%start%+1"
set ver=!cd:~%start%,%len%!
cls
if "%end%"=="" set /p ver=No Version Found, Please Input A Valid Version: ||set /a sE=!sE!+1&&call :getVer
for /l %%i in (0, 1, !len!) do echo.!charList!|find /i "!ver:~%%i,1!">nul&&(cls&&set /p ver=Invalid Version, Please Input A Valid Version: ||call :error invalid_Version 0x72 no_VERSION)
exit /b 0

:buildServer
if %ckBUILD% == 3 (call :error build_Error 0x8E, "build_Attempts=%ckBUILD%")
echo.Version=!ver!
for /l %%i in (260,-1,0) do (echo.\/|find /i "!cd:~%%i,1!">nul&&set /a te=!te!+1)
for /l %%i in (1,1,%te%) do (if %%i neq !te! (cd ../&&if exist BuildTools (goto :cont)) else (cd !ret!&&cd ../&&mkdir BuildTools||call :error build_Error 0x83 mkdir_FAIL))
:cont
cd BuildTools
set buildLoc=%cd%
if not exist spigot-!ver!.jar (
	curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastStableBuild/artifact/target/BuildTools.jar ||call :error build_Error 0x89 no_BuildTool
	cls
	java -jar BuildTools.jar -rev %ver%||call :error build_Error 0x87 buildTool_FAIL
)
cd %ret%
cls
echo.F|xcopy /S /Q /Y /F "%buildLoc%\spigot-%ver%.jar" "!ver!-server.jar">nul||call :error build_Error 0x8C copy_FAIL
if not exist !ver!-server.jar (set /a ckBUILD=%ckBUILD%+1&&goto :buildServer) else (exit /b 0)

:getIP
for /f "tokens=3" %%g in ('route -4 print 0.*') do (if "%%g" neq "" (set gw=%%g||call :error gw_IP 0xF0 fetch_FAIL))
for /f "tokens=*" %%i in ('curl -s ip-adresim.app -4') do set extIP=%%i||call :error ext_IP 0xF5 fetch_FAIL
for /f "tokens=2 delims=:" %%a in ('ipconfig^|find "IPv4"') do (set intIP=%%a&&set intIP=!intIP:~1!||call :error int_IP 0xF6 fetch_FAIL)
exit /b 0

:port
cls
for /f "tokens=2 delims==" %%p in ('find /I "server-port" server.properties') do set port=%%p
if "%port%" equ "" (set /p "port=Please Select An IP Port For The Server (Default 25565): "||set port=25565)&&echo.server-port=!port!>>server.properties||call :error invalid_Port 0xFD save_FAIL
for /l %%i in (0,1,4) do (echo.!charList!.|find /i "!port:~%%i,1!">nul&&(call :error invalid_Port 0xF9 %port%))
if %port% lss 10000 (call :error invalid_Port 0xF3 %port%)
if %port% gtr 65535 (call :error invalid_Port 0xF3 %port%)
exit /b 0

:ram
cls
if "%~1"=="set" (set /p "ram=Input Max RAM Access For Server (Default 2GB): "||set ram=2G)
for /l %%i in (1,1,12) do (echo.GMKB|find /i "!ram:~%%i,1!">nul&&(set "ram=!ram:~0,%%i!!ram:~%%i,1!"&&break))
if /i "%ram:~-1%" equ "B" (if %ram:~0,-1% lss %b% (call :error invalid_RAM 0x5A %ram%))
if /i "%ram:~-1%" equ "K" (if %ram:~0,-1% lss %k% (call :error invalid_RAM 0x5A %ram%))
if /i "%ram:~-1%" equ "M" (if %ram:~0,-1% lss %m% (call :error invalid_RAM 0x5A %ram%))
if /i "%ram:~-1%" equ "B" (set ram=!ram:~0,-1!)
exit /b 0

:batSettings
call :port
call :getIP
if not exist batch.settings (
	call :getVer&call :ram set&call :batchRefresh ver !ver!&call :batchRefresh skip false&call :batchRefresh ram !ram!&call :batchRefresh backDef No&call :batchRefresh backLoc !userprofile!\Desktop\Server_Backups
)
for %%i in (*run*.bat) do set runFile=%%i
for /f "tokens=*" %%r in ('find /i "restart-script" spigot.yml') do set rstart=%%r
for /f "tokens=2 delims==" %%v in ('find /i "version" batch.settings') do set ver=%%v
for /f "tokens=2 delims==" %%s in ('find /i "skip" batch.settings') do set skip=%%s
for /f "tokens=2 delims==" %%r in ('find /i "ram" batch.settings') do set ram=%%r&if "%ram%" neq "" call :ram
for /f "tokens=2 delims==" %%a in ('find /i "address" batch.settings') do set address=%%a
for /f "tokens=2 delims==" %%d in ('find /i "backup-Default" batch.settings') do set backDef=%%d
for /f "tokens=2 delims==" %%l in ('find /i "backup-Location" batch.settings') do set backLoc=%%l
if "%ver%"=="" call :getVer&&call :batchRefresh ver !ver!
if "%skip%"=="" call :batchRefresh skip false
if "%ram%"=="" call :ram set&&call :batchRefresh ram !ram!
if "%address%"=="" set address=!extIP!
if "%backDef%"=="" call :batchRefresh backDef No
if "%backLoc%"=="" call :batchRefresh backLoc !userprofile!\Desktop\Server_Backups
exit /b 0

:batchRefresh
set "%~1=%~2"&& (echo.version=!ver!>batch.settings&&echo.skip-UPnP=!skip!>>batch.settings&&echo.ram=!ram!>>batch.settings&&echo.address=!address!>>batch.settings&&echo.backup-Default=!backDef!>>batch.settings&&echo.backup-Location=!backLoc!>>batch.settings||call :error bat_Update 0xA8 FAIL)
exit /b 0

:mapCheck
cls
for %%i in (*portmapper*.jar) do set portFile=%%i||set "portFile="
if /i "!portFile!" neq "" (ren !portFile! portmapper.jar)
if not exist portmapper.jar (
	echo.If You Don't Have The Port Mapper You Will Need To Port Forward Manually, To Do This You Will Need To Sign In To Your Defaul Gateway At !gw!, The Port Mapper Does Not Work If You Are Hosting A Network Bridge On This Host Device. Get The UPnP Port Mapper Version 2.1.1 From https://sourceforge.net/projects/upnp-portmapper/files/v2.1.1/portmapper-2.1.1.jar
	set /p "skip=Do You Want To Skip The Portmapper Check In The Future (Y/ N): "||set skip=%skip%
	echo.yes|find /i "!skip!">nul&&(call :batchRefresh skip true)||(call :batchRefresh skip false)
	echo.This Can Be Changed In The batch.settings File To Re-enable This Check.&&timeout 5 /nobreak>nul
)
exit /b 0

:error
cd %ret%
cls
if %~1==ending (
	echo.[%time:~0,-3%] Server.Backup: !backup!>>logs\latest.log
	echo.[%time:~0,-3%] Server.Name: !name!>>logs\latest.log
	echo.[%time:~0,-3%] Server.Flags: !sE!>>logs\latest.log
	exit /b 0
)
set /a sE=%sE%+1
echo.Error: %~2&&echo.[%time:~0,-3%] System.Error: %~2>>logs\latest.log
echo.Tag: %~1&&echo.[%time:~0,-3%] System.Tag: %~1>>logs\latest.log
echo.Value: %~3&&echo.[%time:~0,-3%] System.Value: %~3>>logs\latest.log
if exist error-Codes.txt (
	for /f "tokens=2 delims=-" %%e in ('find /i "%~2" error-Codes.txt') do set des=%%e
	if "!des!" neq "" (echo.Description:!des!&&echo.[!time:~0,-3!] System.Description:!des!>>logs\latest.log)
)
pause

:end
endlocal
exit
