@echo off
timeout /T 10 /nobreak
IF EXIST "%~dp0\neoInstall" RD "%~dp0\neoInstall" /S /Q
IF EXIST "%~dp0\neoSource" RD "%~dp0\neoSource" /S /Q
IF EXIST "%~dp0\neo42-Uerpart" RD "%~dp0\neo42-Uerpart" /S /Q
DEL %0