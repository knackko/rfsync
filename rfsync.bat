@echo off
set cd_extract=%cd:~0,72%
set path=%PATH%;%cd_extract%\rfsync\cygwin\bin
set CYGWIN=nodosfilewarning
cd rfsync
start mintty -s 80,30  bash "%cd:~0,72%\script.sh"