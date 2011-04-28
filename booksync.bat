@echo off

if [%1] == [] (
    echo Missing disk letter!
    exit 1
) else (
    set disk=%1\
)
set src="G:\files\library\fiction\books-good"
set dst=%disk%

echo Copying...
robocopy %src% %dst% /MIR
