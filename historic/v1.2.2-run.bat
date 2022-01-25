::Version: 1.2.3
@echo off
setlocal enableextensions enabledelayedexpansion

set ckBUILD=0&set ckEULA=0&set ckRES=0&set sE=0
set lp=
set m=512
set /a k=%m%*1024
set /a b=%k%*1024
set numList=0123456789
set link=https://sourceforge.net/projects/upnp-portmapper/files/v2.1.1/portmapper-2.1.1.jar
set ops=batch.settings&set log=logs\latest.log&set "arqs=%date:~-4%-%date:~3,2%-%date:~0,2%-"


:getName
set ret=%cd%
for /l %%i in (-1,-1,-128) do (echo.\/|find "!cd:~%%i,1!">nul&&(title Server !name!&goto :run)||(set name=!cd:~%%i!||call :log dir_Check 0xA2 fetch_FAIL))

:run
call :batCall
call :mapCheck
if not exist !ver!-server.jar (call :buildServer)
if %ckEULA%==3 (call :log eula_Set 0xD8 false)
if %ckRES%==3 (call :log restart_Set 0xD9 false)
cls
echo.Join Externally Using !address![:!port!]
echo.Or Internally Using !intIP!:!port!
echo.
echo.Version=%ver%
echo.RAM=%ram%B
echo.
call :mapSet add&java -Xmx!ram! -jar !ver!-server.jar nogui||call :log server_Strt 0xD4 FAIL

:chk
find /i "agree to the EULA" %log%>nul&&(set /a ckEULA=%ckEULA%+1&set /a sE=!sE!+1&echo.&&echo.Use This Time To Edit The Server Properties To How You Wish.&&pause>nul|echo.Press Any Key To Retry...&&goto :run)
find /i "Startup script" %log%>nul&&(cls&set /a ckRES=!ckRES!+1&set /a sE=!sE!+1&echo.&&echo.In Order For The Restart Command To Work You Must Edit Spigot.yml And Change "!rs!" to "restart-script: %runFile%".&&pause>nul|echo.Press Any Key To Restart...&&goto :run)
find /i "Attempting to restart" %log%>nul&&exit
call :mapSet delete
echo.true|find /i "%bun:~1%">nul&&exit
choice /c YN /n /m "Do You Want To Backup Your Server (Y/ N): "
if %errorlevel% equ 1 (goto :backup&call :log end back) else (call :log end&&exit)

:backup
set backup=%backLoc%\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%
xcopy /S /Q /Y /F /I "..\%name%" "%backup%"||call :log backup_Comp 0x4D FAIL
echo.Your Server Has Been Backed Up To %backup%.&pause&&exit

:ver
cls&&echo.Fetching Version.
for /l %%i in (3,1,260) do (echo.!numList!|find /i "!cd:~%%i,1!">nul&&(if "!start!"=="" (set /a start=%%i) else (set /a end=%%i)))
set /a "len=%end%-%start%+1"
set ver=!cd:~%start%,%len%!
if "!ver!"=="%cd:~0,-1%" (set /p ver=No Version Found, Please Input A Valid Version: ||(set /a sE=!sE!+1&&call :ver||(call :log inv_Version 0x72 bad_FETCH)))
:loop
cls&if "!ver:~%lp%!"=="" exit /b
echo.!numList!.|find /i "!ver:~%lp%,1!">nul||(set /p ver=Invalid Version, Please Input A Valid Version: &&set lp=||call :log inv_Version 0x73 no_VERSION)
set /a lp=%lp%+1&&goto :loop||call :log loop_Fail 0xC3 no_INC

:buildServer
if %ckBUILD% == 3 (call :log build_Err 0x8E, "build_Attempts=%ckBUILD%")
echo.Version=!ver!
for /l %%i in (260,-1,0) do (echo.\/|find /i "!cd:~%%i,1!">nul&&set /a te=!te!+1)
for /l %%i in (1,1,%te%) do (if %%i neq !te! (cd ../&&if exist BuildTools (goto :cont)) else (cd !ret!&&cd ../&&mkdir BuildTools||call :log build_Err 0x83 mkdir_FAIL))
:cont
cd BuildTools
set buildLoc=%cd%
curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastStableBuild/artifact/target/BuildTools.jar||call :log build_Err 0x89 no_BuildTool
cls
java -Xmx%ram% -jar BuildTools.jar --rev %ver% --output-dir %ret%||call :log build_Err 0x87 buildTool_FAIL
cd %ret%&cls
ren spigot-%ver%.jar %ver%-server.jar||(set /a ckBUILD=%ckBUILD%+1&&goto :buildServer)
exit /b

:IP
for /f "tokens=3" %%g in ('route print 0.*') do (if "%%g" neq "" (set gw=%%g||call :log gw_IP 0xF0 fetch_FAIL))
for /f "tokens=*" %%i in ('curl -s ip-adresim.app -4') do set extIP=%%i||call :log ret_IP 0xF5 fetch_FAIL
for /f "tokens=2 delims=:" %%a in ('ipconfig^|find "v4"') do (set intIP=%%a&&set intIP=!intIP:~1!||call :log ret_IP 0xF6 fetch_FAIL)
exit /b

:port
cls&for /f "tokens=2 delims==" %%p in ('find /I "server-port" server.properties') do set port=%%p
if "%port%" equ "" (set /p "port=Please Select An IP Port For The Server (Default 25565): "||set port=25565)
if %port% lss 1024 (call :log inv_Port 0xF3 %port%)
if %port% gtr 65535 (call :log inv_Port 0xF3 %port%)
for /l %%i in (0,1,4) do (if "!port:~%%i,1!" neq "" (echo.!numList!|find /i "!port:~%%i,1!">nul||call :log inv_Port 0xF9 %port%))
echo.server-port=!port!>>server.properties||call :log inv_Port 0xFD save_FAIL
exit /b

:ram
cls
if "%~1"=="set" (set /p "ram=Input Max RAM Access For Server (Default 2GB): "||set ram=2G)
for /l %%i in (1,1,12) do (echo.GMKB|find /i "!ram:~%%i,1!">nul&&(set ram=!ram:~0,%%i!!ram:~%%i,1!&&break))
if /i "%ram:~-1%" equ "B" (if %ram:~0,-1% lss %b% (call :log inv_RAM 0x5A %ram%))
if /i "%ram:~-1%" equ "K" (if %ram:~0,-1% lss %k% (call :log inv_RAM 0x5A %ram%))
if /i "%ram:~-1%" equ "M" (if %ram:~0,-1% lss %m% (call :log inv_RAM 0x5A %ram%))
exit /b

:batCall
set "address="
call :port&call :IP
for %%i in (*run*.bat) do set runFile=%%i
for /f "tokens=*" %%r in ('find /i "script" spigot.yml') do set rs=%%r
for /f "tokens=2 delims=:" %%b in ('find /i "bun" spigot.yml') do set bun=%%b
for /f "tokens=2 delims==" %%v in ('find /i "vers" %ops%') do set ver=%%v
for /f "tokens=2 delims==" %%s in ('find /i "skip" %ops%') do set skip=%%s
for /f "tokens=2 delims==" %%r in ('find /i "ram" %ops%') do set ram=%%r
for /f "tokens=2 delims==" %%a in ('find /i "add" %ops%') do set address=%%a
for /f "tokens=2 delims==" %%d in ('find /i "Def" %ops%') do set backDef=%%d
for /f "tokens=2 delims==" %%l in ('find /i "Loc" %ops%') do set backLoc=%%l
if "%ver%"=="" call :ver&&call :batRfrsh ver !ver!
if "%skip%"=="" call :batRfrsh skip false
if "%ram%"=="" call :ram set&&call :batRfrsh ram !ram!
if "%backDef%"=="" call :batRfrsh backDef No
if "%backLoc%"=="" call :batRfrsh backLoc !userprofile!\Desktop\Server_Backups
if "%address%"=="" set address=!extIP!
exit /b

:batRfrsh
set "%~1=%~2"&& (echo.version=!ver!>%ops%&&echo.skip-UPnP=!skip!>>%ops%&&echo.ram=!ram!>>%ops%&&echo.address=!address!>>%ops%&&echo.backup-Default=!backDef!>>%ops%&&echo.backup-Location=!backLoc!>>%ops%||call :log bat_Update 0xA8 FAIL)
exit /b

:mapCheck
cls&for %%i in (*portmap*.jar) do set portFile=%%i
if %skip%==false (
	if /i "!portFile!" neq "" (ren !portFile! portmap.jar)
	if not exist portmap.jar (
		echo.If You Don't Have The Port Mapper You Will Need To Port Forward Manually, To Do This You Will Need To Sign In To Your Default Gateway At !gw!, The Port Mapper Does Not Work If You Are Hosting A Network Bridge On This Host Device. Get The UPnP Port Mapper Version 2.1.1 From !link!
		choice /c YN /n /m "Do You Want To Get It Now (Y/ N): "
		if !errorlevel! equ 1 (start !link!) else (
			choice /c YN /n /m "Do You Want To Skip The Portmapper Check In The Future (Y/ N): "
			if !errorlevel! equ 1 (call :batRfrsh skip true) else (call :batRfrsh skip false)
			echo.This Can Be Changed In The %ops% File To Re-enable This Check.&&timeout 3 /nobreak>nul
		)
	)
)
cls&exit /b

:mapSet
if exist portmap.jar (java -jar portmap.jar -%~1 -externalPort %port% -internalPort %port% -protocol TCP -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft>nul||call :log port_Set 0x2E %~1_FAILED)
exit /b

:arq
cd logs
if exist "latest.log" (
	for /l %%i in (1,1,9999) do (if not exist "%arqs%%%i.log.*" (tar -cf %arqs%%%i.log.tar latest.log)&&del latest.log&&cd %ret%&exit /b)
)

:log
cd %ret%&cls
if %~1==end (
	if "%~2"=="back" (echo.[%time:~0,-3%] Server.Backup: !backup!>>%log%)
	echo.[%time:~0,-3%] Server.Name: !name!>>%log%
	echo.[%time:~0,-3%] Server.Flags: !sE!>>%log%
	exit /b
)
call :arq
set /a sE=%sE%+1
echo.Error: %~1&&echo.[%time:~0,-3%] Error.Name: %~1>>%log%
echo.Tag: %~2&&echo.[%time:~0,-3%] Error.Tag: %~2>>%log%
echo.Value: %~3&&echo.[%time:~0,-3%] Error.Value: %~3>>%log%
if exist error-Codes.txt (
	for /f "tokens=2 delims=-" %%e in ('find /i "%~2" error-Codes.txt') do set des=%%e
	if "!des!" neq "" (echo.Description:!des!&&echo.[%time:~0,-3%] Error.Description:!des!>>%log%)
)
pause
exit