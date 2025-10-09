@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: %0 ^<filename^>
    echo File should contain one number per line
    exit /b 1
)

if not exist "%~1" (
    echo File "%~1" not found!
    exit /b 1
)

echo Converting numbers from file:
echo ============================

for /f "usebackq delims=" %%n in ("%~1") do (
    set "num=%%n"
    if defined num (
        for /f "delims=" %%s in ('powershell "!num!/1000"') do (
            echo !num! = %%s
        )
    )
)
