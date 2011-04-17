@echo off

if [%1] == [] (
    echo Missing disk letter!
    exit 1
) else (
    set disk=%1\
)
set src="G:\files\library\fiction\books-good"
set dst=temp

goto main

:silent
    %* >nul 2>&1
    exit /b 0

:main
pushd %disk%
if errorlevel 1 exit 1

echo Prepare for copying...
call :silent mkdir %dst%
for /F "delims=" %%f in ('dir /B "*, *"') do call :silent move /Y "%%f" %dst%
call :silent move /Y unread %dst%

echo Copying...
robocopy %src% %dst% /MIR

echo Restoring working state...
pushd %dst%
for /F "delims=" %%f in ('dir /B "*.*"') do call :silent move /Y "%%f" %disk%
popd
rmdir %dst%

popd
