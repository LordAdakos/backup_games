
@echo off
SETLOCAL EnableDelayedExpansion
::================================CHANGE THESE AS NEEDED=====================================

::Location of the saves (replace XXXXX with your user ID)
set PATH=C:\Users\USERNAME\Documents\Saved Games\Hades

::Location to save the backups to
set BACKUPPATH=D:\Dropbox\Games\Hades\Saves

::Log path
set LOGPATH=%BACKUPPATH%

::FLAG to do a backup only if save has changed, set to 0 if want to backup no matter what
set /a CHK=1

::If you dont want to schedule it and instead would like to use this script as something you run while you play 
::in the background then set TIMER=1. It will ask you how often you want to run it (in minutes).
set /a TIMER=0
::Date format - Possible options are US, EU, YMD. Examples: US 08/17/2018 | EU 17/08/2018 | YMD 2018/08/17
set DATEFORMAT=YMD
::If you are not using default path for 7zip or WinRar you can change them here
::It is ok to not have either, then standard zip format will be used if thats the case
::Reasons to use 7zip - Better compression, free (WILL BE PREFERRED OVER WINRAR IF INSTALLED)
::Reasons to use WinRar - Has 5% baked in recovery in case recovery is needed
set SZIPPATH=C:\Program Files\7-Zip
set WRARPATH=C:\Program Files\WinRAR

::============DO NOT CHANGE ANYTHING BELOW UNLESS YOU KNOW WHAT YOU ARE DOING================
if %DATEFORMAT% == US goto DATEVALID
if %DATEFORMAT% == EU goto DATEVALID
if %DATEFORMAT% == YMD goto DATEVALID
cls
color 0C
echo Invalid date format %DATEFORMAT%
echo Must be either US, EU or YMD
echo.
pause
goto END
:DATEVALID
if %DATEFORMAT% == US set DF=MM-dd-yyyy_HH-mm-ss
if %DATEFORMAT% == EU set DF=dd-MM-yyyy_HH-mm-ss
if %DATEFORMAT% == YMD set DF=yyyy-MM-dd_HH-mm-ss
set /a USESZIP=0
set /a USEWRAR=0
if exist "%SZIPPATH%" (set /a USESZIP=1)
if %USESZIP% EQU 1 goto SKIPWINRAR
if exist "%WRARPATH%" (set /a USEWRAR=1)
:SKIPWINRAR
if %TIMER% == 0 goto SKIPTIMER

set /p CLK="How often do you want to backup (enter minutes): "
set /a SECS=%CLK%*60 
:SKIPTIMER
if %USESZIP% == 0 goto CHECKWRAR
if exist "%SZIPPATH%\7z.exe" (set SZIPPATH=%SZIPPATH%\7z.exe) else (set SZIPPATH=%SZIPPATH%\7za.exe)
if exist "%SZIPPATH%" (color 0A & echo Found 7zip & goto CHECKPATH)
cls
color 0E
echo WARNING! 
echo Cannot find 7-zip in %SZIPPATH%
echo Download it from https://www.7-zip.org/download.html
echo.
echo Checking for WinRar

:CHECKWRAR
if exist "%WRARPATH%\rar.exe" (set /a USEWRAR=1 & set /a USESZIP=0 & echo Found WinRar & color 0D) else (color 0F
	echo Could not find 7zip or Winrar
	echo Falling back to standard zip
	set /a USESZIP=0
	set /a USEWRAR=0)

:CHECKPATH
if exist "%PATH%" goto CHECKBACKUPPATH
cls
echo ERROR!
echo Cannot find %PATH% 
pause
goto END

:CHECKBACKUPPATH
if exist "%BACKUPPATH%" goto RUN
mkdir "%BACKUPPATH%"
if exist "%BACKUPPATH%" goto RUN
cls
echo ERROR!
echo Cannot create %BACKUPPATH%
echo To store backups in
echo Need Admin rights?
pause
goto END

:RUN
if not exist "%SystemRoot%\system32\WindowsPowerShell\v1.0\PowerShell.exe" (set /a PWRSH=0) else (set /a PWRSH=1)
if not exist "%BACKUPPATH%\DATA_last_cksum.txt" goto BACKUP
if %CHK% == 0 goto BACKUP

::"%SystemRoot%\system32\CertUtil" -hashfile "%PATH%\remote\SAVEDATA1000" MD5 > "%BACKUPPATH%\DATA_curr_cksum.txt"
dir "%PATH%" /s | "%SystemRoot%\system32\findstr" /V /R "^(.+?)bytes free" > "%BACKUPPATH%\tmphashc"
"%SystemRoot%\system32\CertUtil" -hashfile "%BACKUPPATH%\tmphashc" MD5 > "%BACKUPPATH%\DATA_curr_cksum.txt"
del "%BACKUPPATH%"\tmphashc	
	
for /f "tokens=1*delims=:" %%G in ('%SystemRoot%\system32\findstr /n "^" "%BACKUPPATH%\DATA_last_cksum.txt"') do if %%G equ 2 ( 
	set PREV=%%H)
	set PREV=%PREV: =%
	echo Previous: %PREV%
	
for /f "tokens=1*delims=:" %%G in ('%SystemRoot%\system32\findstr /n "^" "%BACKUPPATH%\DATA_curr_cksum.txt"') do if %%G equ 2 ( 
	set CURR=%%H)
	set CURR=%CURR: =%
	echo Current:  %CURR%

if "%PREV%" == "%CURR%" (
	echo Checksums match. New backup not needed.
	echo %date% %time% - Backup requested, file is same as last time. NOT backing up. >> "%LOGPATH%\DATA_saves_log.txt"
	echo If you would like to backup either way, please set CHK=0 in the file. >> "%LOGPATH%\DATA_saves_log.txt"
	echo Previous: %PREV% >> "%LOGPATH%\DATA_saves_log.txt"
	echo Current:  %CURR% >> "%LOGPATH%\DATA_saves_log.txt"
	echo. >> "%LOGPATH%\DATA_saves_log.txt"
	goto TIMERCHECK
)

:BACKUP
::if %CHK% == 1 "%SystemRoot%\system32\CertUtil" -hashfile "%PATH%\remote\SAVEDATA1000" MD5 > "%BACKUPPATH%\DATA_last_cksum.txt"
if %CHK% == 1 ( dir "%PATH%" /s | "%SystemRoot%\system32\findstr" /V /R "^(.+?)bytes free" > "%BACKUPPATH%"\tmphashl	
"%SystemRoot%"\system32\CertUtil -hashfile "%BACKUPPATH%"\tmphashl MD5 > "%BACKUPPATH%"\DATA_last_cksum.txt
del "%BACKUPPATH%"\tmphashl	
)

if %PWRSH% == 1 (for /f %%d in ('%SystemRoot%\system32\WindowsPowerShell\v1.0\PowerShell.exe get-date -format "{%DF%}"') do set FILENAME=DATA_Save_%%d) else (goto ALTDATE) 

goto SKIPALTDATE
:ALTDATE
if 20 NEQ %date:~0,2% (set d=%date:~4,10%) else (set d=%date%)
if / == %date:~2,1% (set d=%date%)
if - == %date:~2,1% (set d=%date%)
set tm=%time:~0,8%
set d=%d:/=-% & set tm=%tm::=-% 
set tm=%tm:.=-% 
set FILENAME=DATA_Save_%d%_%tm%
set FILENAME=%FILENAME: =% 
:SKIPALTDATE
if %USESZIP% == 1 ("%SZIPPATH%" a -y "%BACKUPPATH%\%FILENAME%" "%PATH%")
if %USESZIP% == 1 goto NEXT
if %USEWRAR% == 1 ("%WRARPATH%\rar.exe" a -y -ep1 -rr5 "%BACKUPPATH%\%FILENAME%" "%PATH%") 
if %USEWRAR% == 1 goto NEXT
"%SystemRoot%\system32\WindowsPowerShell\v1.0\PowerShell.exe" Compress-Archive -LiteralPath "'%PATH%'" -DestinationPath "'%BACKUPPATH%\%FILENAME%.zip'" -Force
:NEXT
if not exist "%BACKUPPATH%\DATA_curr_cksum.txt" set CURR="N/A - First backup or CHK=0"
if exist "%BACKUPPATH%\%FILENAME%.*" (
	echo Saved %FILENAME% MD5: %CURR%
	echo Saved %FILENAME% MD5: %CURR% >> "%LOGPATH%\DATA_saves_log.txt"
	echo. >> "%LOGPATH%\DATA_saves_log.txt"
	) else (echo ERROR - CANT CREATE BACKUP "%FILENAME%" >> "%LOGPATH%\DATA_saves_log.txt")
:TIMERCHECK
if %TIMER% == 1 ( 
	"%SystemRoot%\system32\TIMEOUT" /T %SECS% /NOBREAK
	goto RUN)

:END
