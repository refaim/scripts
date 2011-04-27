@echo off

:: Miranda IM update script
:: Usage: miranda-update [packages]
:: Example: miranda-update unicode unicode-contrib

set wget=wget
set sevenzip=7z

set miranda=G:\utils\miranda
set bit=32
set executable=miranda%bit%.exe
set tempdir=%TEMP%\miranda

goto main


:delete
del /q %* >nul 2>&1
exit /b 0


:cleanup
echo Cleaning...
rmdir /s /q "%tempdir%" >nul 2>&1
exit /b 0


:check_for_running
for /F "delims=" %%a in ('tasklist /FI "IMAGENAME eq %executable%.exe" ^| findstr "No tasks are running"') do (
    set result="%%a"
)
if [%result%] equ [] (
    echo Close Miranda IM before update.
    exit /b 1
)
exit /b 0


:find_miranda
set changelog="%miranda%\changelog.txt"
set version_pattern="\* New in [a-z0-9\.]"

echo Recognizing installed Miranda version...
if not exist %changelog% (
    echo Changelog not found. Specify the correct path to Miranda!
    exit /b 1
)^
else (
    for /F "tokens=4" %%a in ('findstr /B /I %version_pattern% %changelog%') do (
        set installed_version=%%a
        goto miranda_found
    )
    :miranda_found
    echo Found Miranda IM %installed_version%.
    exit /b 0
)


rem get_package(name)
:get_package
set list=http://code.google.com/p/miranda/downloads/list
set pattern=*%1.7z
set urlpattern=http.%pattern%
for /F "tokens=3 delims== " %%a in ('%wget% -q -O - %list% ^| findstr /I %urlpattern%') do set download_url=%%a
for /F "tokens=4 delims=/"  %%a in (%download_url%) do set filename=%%a

for /F "tokens=3 delims=v-" %%a in (%download_url%) do set new_version=%%a
if %installed_version% equ %new_version% (
    echo %1: no updates found.
    exit /b 0
)^
else set updates_found="yes"

echo Downloading %filename%...
pushd "%tempdir%"
%wget% -O %filename% %download_url%
if errorlevel 1 (
    echo Downloading failed.
    exit /b 1
)
echo Downloading completed.
echo Extracting %filename%...
%sevenzip% x %filename% >nul 2>&1
if errorlevel 1 (
    echo Extracting failed.
    exit /b 1
)
echo Extracting completed.
call :delete %filename%
popd

exit /b 0


:backup
setlocal
set backupfile=backup.7z
pushd %miranda%

call :delete %backupfile%

echo Creating backup...
%sevenzip% a -r %backupfile% *.* -x!*.dat >nul 2>&1
if errorlevel 1 (
    echo Backup failed.
    exit /b 1
)
echo %backupfile% created.

popd
endlocal
exit /b 0


:update
goto update_main

    :accurate_dir_update
    pushd "%tempdir%\%1"
    for /F %%f in ('dir /B') do (
        if exist "%miranda%\%1\%%f" (
            copy /Y %%f "%miranda%\%1\%%f" >nul 2>&1
        )
    )
    popd
    exit /b 0

:update_main
echo Updating...
copy /Y "%tempdir%\*.*" "%miranda%" >nul 2>&1
call :accurate_dir_update plugins
call :accurate_dir_update icons
exit /b 0


:main
call :check_for_running || exit 1
call :find_miranda || exit 1

echo Checking for updates...
call :cleanup
echo Creating temp directory...
mkdir "%tempdir%" || exit 1

set updates_found="no"
for %%p in (%*) do (
    call :get_package %%p || exit 1
)

if %updates_found% equ "yes" (
    call :backup || exit 1
    call :update || exit 1

)
call :cleanup

echo Starting...
pushd "%miranda%"
start %executable%
popd

exit 0
