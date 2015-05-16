@echo off
REM.-- Prepare the Command Processor --
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
@cd /d "%~dp0"
cd ..
set cd_extract=%cd:~0,72%
echo Fixing permissions in %cd_extract%
echo Please wait
icacls "%cd_extract%" /grant *S-1-5-11:(OI)(CI)F /T
takeown /F "%cd_extract%" /R
echo ..................
echo ......END.........
echo ..................
pause
