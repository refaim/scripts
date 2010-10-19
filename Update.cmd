@echo off
set wget=wget
set sevenzip=7z

set fid=file_id.diz
set version_pattern="Far Manager v2.0 build [0-9]+ x86"

call :find_local
echo Checking for updates...
call :find_remote
if %installed_version% equ %new_version% (
echo No updates found.
goto :EOF
)^
else (
echo Updates found! New version: %new_version%.
call :update
goto :EOF
)

:find_local
if not exist %fid% (
echo FAR 2 not found.
goto :EOF
)^
else (call :parse_version)
echo Found FAR v2.0 build %installed_version%.
set fardir=%CD%
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
del %backupfile% >nul 2>&1
%sevenzip% a -r %backupfile% * >nul 2>&1

echo Downloading...
del /s /q "%tempdir%" %tempfile% >nul 2>&1
%wget% -q -O %tempfile% %download_url%

echo Extracting...
%sevenzip% x %tempfile% -o%tempdir% >nul 2>&1

echo Updating...
taskkill.exe /IM far.exe >nul 2>&1
taskkill.exe /F /IM far.exe >nul 2>&1
copy /Y %tempdir%\*.* %CD% >nul 2>&1

pushd "%tempdir%\plugins"
for /F %%f in ('dir /B') do (
if exist "%fardir%\plugins\%%f" (
copy /Y %%f "%fardir%\plugins\%%f" >nul 2>&1
)
)
popd

echo Removing temporary files...
del /s /q "%tempdir%" %tempfile% >nul 2>&1

echo Starting...
start RunFar.cmd