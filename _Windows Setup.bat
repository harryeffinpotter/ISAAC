@echo off
CLS
TITLE ISAAC - Instant Service Account Adder ^& Configurator - Windows Edition
echo WARNING: do NOT run this on your headless server ^!
echo Make sure you have your oauth json saved to directory before proceeding (it doesnt have to be named credentials.json, it will be auto renamed if it starts with "client")
echo. 
pause
del backup /s /q >> SetupLog.txt
winget install -e --id Python.Python.3.10
set PATH=%PATH%;%USERPROFILE%\AppData\Local\Programs\Python\Python310\Scripts;%USERPROFILE%\AppData\Local\Programs\Python\Python310
mkdir backup >> SetupLog.txt

cls
echo Backing up directory, removing previous backup, and cleaning any files leftover from previous runs and cleaning up directory...
timeout /t 6 /nobreak > nul
copy -a "*" ".\backup"   >> SetupLog.txt
del "emails.txt" /s /q >> SetupLog.txt
del "*.csv" /s /q >> SetupLog.txt
del /s /q ".\accounts\*.json"  >> SetupLog.txt
del /s /q ".\credentials\*.pickle"  >> SetupLog.txt
del /s /q ".\*.pickle"  >> SetupLog.txt
rem Install Properties-updates, I believe this was a key piece I missed last time.
move .\client*.json .\credentials.json >> SetupLog.txt
if "%ERRORLEVEL%" == "1" (goto :CheckForCredentials) else (goto :Continue)

:CheckForCredentials
if NOT EXIST ".\credentials.json" (goto :ExitNow) else (goto :Continue)

:ExitNow
echo.
echo.
echo credentials.json file not found! This file is required for your SA, which can be created as described at the following link @ step 3, part 1"
echo https://github.com/xyou365/AutoRclone and saved as credentials.json in this folder.
echo.
echo.
echo Please fix this and try again.
echo.
echo.
timeout /t 5
exit 1

:Continue
@ECHO off
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\Scripts\pip3.exe" install google-api-python-client google-auth-httplib2 google-auth-oauthlib
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\Scripts\pip3.exe" install -r "%~dp0requirements.txt" 
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" -m pip install --upgrade pip
cls
echo Next you must confirm authorization of the SA account generation script, copy and paste the link into your browser, or if you're using terminal just ctrl+click it.
echo.
echo.
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" gen_sa_accounts.py 
echo. 
echo.

:START
set /a COUNT=0
setlocal EnableDelayedExpansion
cls
echo Choose which account to add the SA's to:
FOR /F "tokens=* USEBACKQ" %%F IN (`"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" gen_sa_accounts.py --list-projects`) DO (
set /a COUNT=COUNT+1
set var=%%F
if "!COUNT!"=="2" (echo 1 - %%F & set "PROJID=%%F" & set CHOICE1=%%F)
if "!COUNT!" gtr "2" (
set /a RESULT=COUNT-1
 echo !RESULT! - %%F
call set CHOICE!RESULT!=%%F
)
)
if "%COUNT%"=="2" (echo. & echo Only project automatically selected^: %PROJID% & echo. & timeout /t 5 & goto :ProjectIDChosen ) else (
:CHOOSENUM
echo.
echo Which project are you trying to add SA's to? Pick the matching number.
echo Choose 1-!RESULT!:
set /p chosen=
if !chosen! gtr !COUNT! (echo INCORRECT CHOICE.. ENTER A NUMERICAL VALUE ONLY. && goto :CHOOSENUM) else (
set PROJID=!CHOICE%chosen%!
)
)

set "PROJID=!CHOICE%chosen%!"

:isokay
echo.
echo You chose: %PROJID%
echo.
echo Is that OK[Y/N]?
set /p isok=
if "%isok%"=="N" endlocal & goto :START
if "%isok%"=="n" endlocal & goto :START
if "%isok%"=="Y" goto :ProjectIDChosen
if "%isok%"=="y" goto :ProjectIDChosen
echo Incorrect answer given... & timeout /t 5 & goto :isokay


:ProjectIDChosen
:DeleteSas
cls
echo Would you like to delete previous Service Accounts on this account (i.e. you have lost the files)[Y/N]?
set /p delsas=
if "%delsas%" EQU "Y" goto :delsas
if "%delsas%" EQU "y" goto :delsas
if "%delsas%" EQU "n" goto :ADDSAS
if "%delsas%" EQU "N" goto :ADDSAS
echo Incorrect answer given... & timeout /t 5 & cls & goto :DeleteSas

:delsas
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" gen_sa_accounts.py --delete-sas "%PROJID%"

:ADDSAS
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" gen_sa_accounts.py --enable-services "%PROJID%"
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" gen_sa_accounts.py --create-sas "%PROJID%"
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" gen_sa_accounts.py --download-keys "%PROJID%"
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" rename_script.py
"%USERPROFILE%\AppData\Local\Programs\Python\Python310\python.exe" GetEmails.py
copy ".\accounts\0.json" ".\accounts\100.json" >> SetupLog.txt
copy ".\token.pickle" ".\credentials\token.pickle" >> SetupLog.txt

