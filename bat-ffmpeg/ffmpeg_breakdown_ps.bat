@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: %0 ^<input_file^> ^<breakdown_numbers...^>
    echo Example: %0 082.mp3 7090 11610 17350
    exit /b 1
)

set "input_file=%~1"
shift /1

if not exist "%input_file%" (
    echo Error: Input file '%input_file%' not found!
    exit /b 1
)

where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo Error: ffmpeg is not installed!
    exit /b 1
)

for %%F in ("%input_file%") do set "filename=%%~nF"

echo Processing: %input_file%
set "breakdowns="
for %%a in (%*) do set "breakdowns=!breakdowns! %%a"
echo Breakdown points:!breakdowns!
echo ==============================================

set counter=1
for %%m in (%*) do (
    set "ms=%%m"
    
    :: Use PowerShell for precise decimal calculation
    for /f "delims=" %%s in ('powershell "!ms!/1000"') do set "seconds=%%s"
    
    if !counter! lss 10 (
        set "part_num=0!counter!"
    ) else (
        set "part_num=!counter!"
    )
    set "output_file=!filename!!part_num!.mp3"
    
    echo Creating segment !counter!: !output_file! (!seconds!s)
    
    ffmpeg -i "!input_file!" -t !seconds! -c copy "!output_file!" -y
    
    if !errorlevel! equ 0 (
        echo ✓ Successfully created: !output_file!
    ) else (
        echo ✗ Failed to create: !output_file!
    )
    
    echo ---
    set /a counter+=1
)

echo All segments processed!
pause