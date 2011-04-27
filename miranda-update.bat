@echo off
set wget=wget
set sevenzip=7z

set miranda=G:\utils\miranda
set changelog="%miranda%\changelog.txt"
set version_pattern="\* New in [a-z0-9\.]"

goto main

:delete
    del /q %* >nul 2>&1
    exit /b 0

:main
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
echo Recognizing installed Miranda version...
if not exist %changelog% (
echo Changelog not found. Specify the correct path to Miranda!
)^
else (call :parse_version)
echo Found Miranda %installed_version%.
exit /b 0

:parse_version
for /F "tokens=4" %%a in ('findstr /B /I %version_pattern% %changelog%') do (
set installed_version=%%a
exit /b 0
)

:find_remote
set list=http://code.google.com/p/miranda/downloads/list
set pattern=*unicode.7z
set urlpattern=http.%pattern%
for /F "tokens=3 delims== " %%a in ('%wget% -q -O - %list% ^| findstr /I %urlpattern%') do set download_url=%%a
for /F "tokens=3 delims=v-" %%a in (%download_url%) do set new_version=%%a
exit /b 0

:update
set tempdir=%TEMP%\miranda-%new_version%
set tempfile="%TEMP%\miranda-%new_version%.7z"

echo Creating backup...
set backupfile="backup.7z"
pushd %miranda%
call :delete %backupfile%
%sevenzip% a -r %backupfile% *.* -x!*.dat >nul 2>&1
if errorlevel 1 (
echo Closing Miranda...
taskkill.exe /IM miranda32.exe >nul
)
popd

echo Downloading...
call :delete /s "%tempdir%" %tempfile%
%wget% -q -O %tempfile% %download_url%

echo Extracting...
%sevenzip% x %tempfile% -o%tempdir% >nul 2>&1

echo Updating...
copy /Y %tempdir%\*.* "%miranda%" >nul 2>&1

pushd "%tempdir%\plugins"
for /F %%f in ('dir /B') do (
if exist "%miranda%\plugins\%%f" (
copy /Y %%f "%miranda%\plugins\%%f" >nul 2>&1
)
)
popd

pushd "%tempdir%\icons"
for /F %%f in ('dir /B xstatus*') do copy /Y %%f "%miranda%\icons\%%f" >nul 2>&1
popd

echo Removing temporary files...
call :delete /s "%tempdir%" %tempfile%

echo Starting...
pushd "%miranda%"
echo %CD%
pause
start miranda32.exe
popd

:EOF
