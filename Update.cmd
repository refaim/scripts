@echo off
set wget=wget
set sevenzip=7z

set fid=file_id.diz
set version_pattern="Far Manager v2.0 build [0-9]+ x86"

goto main

:delete
    del /q %* >nul 2>&1
    exit /b 0


:main
call :check_status
if errorlevel 1 goto :eof
call :find_local
if errorlevel 1 goto :eof
echo Checking for updates...
call :find_remote
if %installed_version% equ %new_version% (
echo No updates found.
goto :eof
)
echo Updates found! New version: %new_version%.
call :update
echo Starting...
start RunFar.cmd
goto :eof


:check_status
for /F "delims=" %%a in ('tasklist /FI "IMAGENAME eq Far.exe" ^| findstr "No tasks are running"') do (
set result="%%a"
)
:: FAR is running
if [%result%] equ [] (
echo Close FAR before update.
exit /b 1
)
exit /b 0


:find_local
if not exist %fid% (
echo FAR 2 not found.
exit /b 1
)
call :parse_version
echo Found FAR v2.0 build %installed_version%.
set fardir=%~dp0
exit /b 0


:parse_version
for /F "tokens=5" %%a in ('findstr /B /I %version_pattern% %fid%') do (
set installed_version=%%a
exit /b 0
)


:find_remote
set meta=http://www.farmanager.com/nightly/update2.php?p=32
set build_pattern=build
set archive_pattern=arc
for /F "tokens=2 delims==" %%a in ('%wget% -q -O - %meta% ^| findstr /B /I %build_pattern%') do set new_version=%%a
for /F "tokens=2 delims==" %%a in ('%wget% -q -O - %meta% ^| findstr /B /I %archive_pattern%') do set archive=%%a
:: strip quotes
set new_version=%new_version:"=%
set archive=%archive:"=%
set download_url=http://farmanager.com/nightly/%archive%
exit /b 0


:update
set tempdir=%TEMP%\far-%new_version%
set tempfile="%TEMP%\%archive%"

echo Creating backup...
set backupfile="farbackup.7z"
call :delete %backupfile%
%sevenzip% a -r %backupfile% * >nul 2>&1

echo Downloading...
call :delete /s "%tempdir%" %tempfile%
%wget% -O %tempfile% %download_url%

echo Extracting...
%sevenzip% x %tempfile% -o%tempdir% >nul 2>&1

echo Updating...
copy /Y %tempdir%\*.* %~dp0 >nul 2>&1

pushd "%tempdir%\plugins"
for /F %%f in ('dir /B') do (
if exist "%fardir%\plugins\%%f" (
copy /Y %%f "%fardir%\plugins\%%f" >nul 2>&1
)
)
popd

echo Removing temporary files...
call :delete /s "%tempdir%" %tempfile%

exit /b 0
