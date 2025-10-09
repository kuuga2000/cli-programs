@echo off
setlocal enabledelayedexpansion

REM --- CONFIGURATION ---
set "INPUT_AUDIO=082.mp3"     REM *** CHANGE THIS to your audio file name ***
set "BREAKPOINTS_FILE=082.txt"
set "OUTPUT_PREFIX=segment_"    REM Output files will be named segment_01.mp3, etc.
set "FFMPEG_PATH=ffmpeg"        REM Assumes FFmpeg is in your system PATH

REM --- INITIALIZATION ---
set "PREV_TIME_MS=0"
set "SEGMENT_COUNT=0"

echo Reading breakpoints from %BREAKPOINTS_FILE%...
echo.

REM --- LOOP THROUGH BREAKPOINTS ---
REM The /f loop reads each line from the text file
for /f "tokens=*" %%a in (%BREAKPOINTS_FILE%) do (
    set /a "CURRENT_TIME_MS=%%a"

    REM Check if the current time is greater than the previous one (prevents errors)
    if !CURRENT_TIME_MS! gtr !PREV_TIME_MS! (
        
        REM Skip the very first line (the 0ms start point)
        if !SEGMENT_COUNT! gtr 0 (
            
            REM Calculate the duration of the *previous* segment
            set /a "DURATION_MS=!CURRENT_TIME_MS! - !PREV_TIME_MS!"
            
            REM --- EXECUTE FFmpeg COMMAND for the completed segment ---
            
            REM Calculate Start Time and Duration in Seconds (FFmpeg prefers seconds)
            REM Note: Batch script division is integer only, so we use full millisecond values for accuracy where possible
            set "START_SEC_DECIMAL=!PREV_TIME_MS!/1000"
            set "END_SEC_DECIMAL=!CURRENT_TIME_MS!/1000"
            
            REM Generate output filename
            set /a "OUTPUT_NUMBER=!SEGMENT_COUNT!"
            
            REM Pad number with leading zero (e.g., 01, 02)
            if !OUTPUT_NUMBER! lss 10 (set "OUTPUT_NAME=%OUTPUT_PREFIX%0!OUTPUT_NUMBER!.mp3") else (set "OUTPUT_NAME=%OUTPUT_PREFIX%!OUTPUT_NUMBER!.mp3")

            echo Splitting: !START_SEC_DECIMAL!s to !END_SEC_DECIMAL!s -> !OUTPUT_NAME!
            
            REM Run the FFmpeg command using -ss (start) and -to (end) for precise cutting
            "%FFMPEG_PATH%" -i "%INPUT_AUDIO%" -ss !START_SEC_DECIMAL! -to !END_SEC_DECIMAL! -c copy "!OUTPUT_NAME!"
        )
        
        REM Update previous time for the next loop iteration
        set "PREV_TIME_MS=!CURRENT_TIME_MS!"
        set /a "SEGMENT_COUNT+=1"
    )
)

REM --- HANDLE THE FINAL SEGMENT (from the last breakpoint to the end) ---

REM The last segment starts at the last breakpoint read (which is stored in PREV_TIME_MS)
set /a "FINAL_SEGMENT_COUNT=!SEGMENT_COUNT!"

REM Calculate the starting time in seconds for the final segment
set "START_SEC_FINAL_DECIMAL=!PREV_TIME_MS!/1000"

REM Generate output filename for the final segment
if !FINAL_SEGMENT_COUNT! lss 10 (set "OUTPUT_NAME=%OUTPUT_PREFIX%0!FINAL_SEGMENT_COUNT!.mp3") else (set "OUTPUT_NAME=%OUTPUT_PREFIX%!FINAL_SEGMENT_COUNT!.mp3")

echo.
echo Final Segment: Starting at !START_SEC_FINAL_DECIMAL!s to End -> !OUTPUT_NAME!
"%FFMPEG_PATH%" -i "%INPUT_AUDIO%" -ss !START_SEC_FINAL_DECIMAL! -c copy "!OUTPUT_NAME!"

echo.
echo --- Splitting Complete ---
echo Check your folder for the 4 split audio files.
pause