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

set "counter=1"
for /f "usebackq delims=" %%n in ("%~1") do (
    set "num=%%n"
    if defined num (
        for /f "delims=" %%s in ('powershell "!num!/1000"') do (
            set "padded=0!counter!"
            echo %%s %~n1!padded:~-2!
            set /a counter+=1
            @REM set "second=%%s"
            @REM echo !second!
        )
    )
)
    

@REM ffmpeg -i 082.mp3 -to 7.09 -c copy 08201.mp3
@REM ffmpeg -i 082.mp3 -ss 7.09 -to 11.61 -c copy 08202.mp3
@REM ffmpeg -i 082.mp3 -ss 11.61 -to 17.35 -c copy 08203.mp3
@REM ffmpeg -i 082.mp3 -ss 17.35 -c copy 08204.mp3
