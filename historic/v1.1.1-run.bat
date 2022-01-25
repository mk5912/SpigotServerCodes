@echo off
setlocal enableextensions enabledelayedexpansion

set /a check=0

:getVer
echo._/\abcdefghijklmnopqrstuvwxyz- |find /i "%cd:~-1%" > nul && (goto :verError) || (
	echo._/\abcdefghijklmnopqrstuvwxyz- |find /i "%cd:~-8,1%" > nul && (
		echo._/\abcdefghijklmnopqrstuvwxyz- |find /i "%cd:~-7,1%" > nul && (set ver=%cd:~-6%) || (set ver=%cd:~-7%)
	) || (set ver=%cd:~-8%)
)

:getRet
set ret=%cd%
for /l %%i in (-1, -1, -50) do (
	echo.\/|find "!cd:~%%i,1!">nul && (set name=!cd:~%%i!&& goto :setTitle) || (echo.>nul)
)

:setTitle
set name=%name:~1%
title Server %name%

:mapCheck
if exist portmapper.jar (
	goto :serverCheck
)

::Creates the batch.settings if can't be found
::with a default skip setting of false.
if not exist batch.settings (
	echo.skip-UPnP=false>batch.settings
	set skip=false
)

::Retrieves the skip value from batch.settings and if
::skip=true then skips the check for portmapper.jar.
for /f "tokens=*" %%s in ('find /I "skip" batch.settings') do set skip=%%s
set skip=%skip:~10%
if /i %skip%==true (goto :serverCheck)

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
	pause>nul|echo.Get The UPnP Port Mapper Version 2.1.1 From https://sourceforge.net/projects/upnp-portmapper/files/v2.1.1/portmapper-2.1.1.jar
	set /p "skip=Do You Want To Skip The Portmapper Check In The Future (Y/ N): "||set skip=no
	echo.yes|find /i "!skip!">nul && (
		echo.skip-UPnP=true>batch.settings
	) || (
		echo.skip-UPnP=false>batch.settings
	)
	echo.This Can Be Changed In The batch.settings File To Re-enable This Check. && timeout 5 /nobreak>nul
)

:serverCheck
if %check%==3 (goto :verError)
if not exist server.jar (
	echo.Version=%ver%
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
if not exist server.jar (set /a check=%check%+1 && goto :serverCheck)

:portFind
cls
find /I "server-port" server.properties>nul
if ErrorLevel 1 (cls) Else (goto :portCheck)

:portSet
set /p por=Please Select An IP Port For The Server (Default 25565): ||set por=25565
echo.server-port=%por%>>server.properties

:portCheck
for /f "tokens=*" %%p in ('find /I "server-port" server.properties') do set port=%%p
set port=%port:~12%
if "%port%"=="" (goto :portSet)
for /l %%i in (0,1,4) do (
	echo.0123456789|find /i "!port:~%%i,1!">nul&&(echo.>nul)||(goto :portError)
)

:ramFind
find /I "ram" server.properties>nul
if ErrorLevel 1 (goto :ramSet) Else (goto :ramCheck)

:ramSet
set /p ram=Input Max RAM Access For Server (Default 2GB): ||set ram=2G
if /i "%ram:~-1%"=="B" (set ram=!ram:~0,-1!|| goto :ramError)
echo.ram=%ram%>>server.properties

:ramCheck
for /f "tokens=*" %%g in ('find /I "ram" server.properties') do set ram=%%g
set ram=%ram:~4%
if "%ram%"=="" (goto :ramSet)
if /i "%ram:~-1%"=="B" (set ram=!ram:~0,-1!|| goto :ramError)
if %ram:~0,-1% lss 512 (
	if "%ram:~-1%" neq "G" (
		set ram=512M
		echo.ram=512M>>server.properties
		echo.server-port=%port%>>server.properties
	)
)

:getIP
for /f "tokens=*" %%i in ('curl -s ip-adresim.app -4') do set extIP=%%i
for /f "tokens=1-2 delims=:" %%a in ('ipconfig^|find "IPv4"') do set intIP=%%b
set intIP=%intIP:~1%

:run
cls
echo.Join Externally Using %extIP%:%port%
echo.Or Internally Using %intIP%:%port%
echo.
echo.RAM=%ram%B
echo.

::Starts the UPnP port forwarding if portmapper is downloaded.
if exist portmapper.jar (
	java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol tcp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft > nul & java -jar portmapper.jar -add -externalPort %port% -internalPort %port% -protocol udp -lib org.chris.portmapper.router.weupnp.WeUPnPRouterFactory -description Minecraft > nul
)

::This is the actual server start.
java -Xmx%ram% -jar server.jar nogui
::This runs a number of post-checks for certain criteria.
find /i "agree to the EULA" logs\latest.log>nul && (echo: && echo.Use This Time To Edit The Server Properties To How You Wish. && pause > nul|echo.Press Any Key To Retry... && goto :portFind)
find /i "Startup script" logs\latest.log>nul && (cls&&echo. && echo.In Order For The Restart Command To Work You Must Edit Spigot.yml Line 26 From restart-script: ./start.sh to restart-script: "runFile".bat Where "runFile" Is The Name Of The Start File.&& pause > nul|echo.Press Any Key To Restart... && goto :portFind)
find /i "Attempting to restart" logs\latest.log>nul && (goto :end)

::Ends the UPnP port forwarding if portmapper is downloaded.
if exist portmapper.jar (
	java -jar portmapper.jar -delete -externalPort %port% -protocol tcp > nul & java -jar portmapper.jar -delete -externalPort %port% -protocol udp > nul
)

set /p backup=Do You Want To Backup Your Server (Y/ N): ||set backup=No
echo.yes|find /i "%backup%"&&(goto :backup)||(goto :end)

:verError
echo.An error has occured: 0x52
echo.Invalid^/ Unrecognised Server Version^!
echo.Had %check% Unsuccessful Build(s), Please Check The Directory Name.
pause
goto :end

:ramError
echo.An error has occured: 0x84
echo.Invalid^/ Unrecognised Server RAM ^(Please Input As %ram:~0,-1% Not %ram%^).
pause
goto :end

:portError
echo.An error has occured: 0xF9
echo.Port Number Can Not Be Recognised, Please Check Your Server Properties.
echo.The Port Can Only Include Numeric Values, No Letters Can Be Included In The Port.
pause
goto :end

:backup
xcopy /S /Q /Y /F /I "..\%name%" "%userprofile%\Desktop\Server_Backups\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%"
echo.Your Server Has Been Backed Up To %userprofile%\Desktop\Server_Backups\%name%_Backup\%date:~8,2%-%date:~3,2%-%date:~0,2%.
pause

:end
echo.Stopping
endlocal
exit