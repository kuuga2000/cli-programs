import argparse
import subprocess
import os
import math

# Use the full ffmpeg command. Assumes ffmpeg is in PATH.
FFMPEG_CMD = 'ffmpeg'

def ms_to_sec(ms):
    """Converts milliseconds (int) to seconds (str) with 3 decimal places."""
    return f"{ms / 1000.0:.3f}"

def run_ffmpeg_command(args):
    """
    Executes the FFmpeg command list.
    Handles errors and checks if FFmpeg is installed.
    """
    try:
        # Executes the command, hiding the typical verbose FFmpeg output 
        # but capturing errors.
        print(f"Executing: {' '.join(args[1:])}") # Print command without 'ffmpeg' prefix
        
        # We suppress stdout but capture stderr for error reporting
        subprocess.run(
            args, 
            check=True, 
            stdout=subprocess.DEVNULL, 
            stderr=subprocess.PIPE, 
            text=True
        )
        return True
    except FileNotFoundError:
        print("\n[FATAL ERROR] FFmpeg command not found.")
        print("Please ensure FFmpeg is installed and accessible in your system's PATH.")
        return False
    except subprocess.CalledProcessError as e:
        print(f"\n[FFMPEG ERROR] Failed to process segment. Return Code: {e.returncode}")
        print(f"FFmpeg Error Output:\n{e.stderr.strip()}")
        return False
    except Exception as e:
        print(f"[UNEXPECTED ERROR] An unexpected error occurred: {e}")
        return False

def split_audio(audio_path, breakpoints_path):
    """
    Reads breakpoints and generates and executes FFmpeg commands to split the audio.
    """
    if not os.path.exists(audio_path):
        print(f"Error: Input audio file not found at '{audio_path}'")
        return
    
    if not os.path.exists(breakpoints_path):
        print(f"Error: Breakpoints file not found at '{breakpoints_path}'")
        return

    # 1. Read and Process Breakpoints
    breakpoints_ms = []
    try:
        with open(breakpoints_path, 'r') as f:
            for line in f:
                try:
                    ms = int(line.strip())
                    if ms > 0: # Only process positive integer breakpoints
                        breakpoints_ms.append(ms)
                except ValueError:
                    print(f"Warning: Skipping invalid line: '{line.strip()}' (must be a positive integer)")
    except Exception as e:
        print(f"Error reading breakpoints file: {e}")
        return
    
    # Sort and ensure uniqueness
    breakpoints_ms = sorted(list(set(breakpoints_ms)))
    
    if not breakpoints_ms:
        print("Error: No valid breakpoints found in the file.")
        return

    # Add the starting point (0ms) to the list to define segments
    points_ms = [0] + breakpoints_ms

    # Get file base name (e.g., '082') and extension (e.g., '.mp3')
    base_name, ext = os.path.splitext(audio_path)
    output_ext = ext if ext else ".mp3" # Use input extension or default to .mp3

    print("-" * 50)
    print(f"Input Audio: {audio_path}")
    print(f"Breakpoints (ms): {points_ms[1:]}")
    print(f"Total Segments: {len(points_ms)}")
    print("-" * 50)

    # 2. Loop and Generate FFmpeg Commands
    success_count = 0
    total_segments = len(points_ms)

    # Iterate through segments (total_segments - 1 is the actual number of cuts)
    for i in range(total_segments):
        start_ms = points_ms[i]
        start_sec = ms_to_sec(start_ms)
        
        # Generate output filename (e.g., 08201.mp3, 08202.mp3)
        segment_num = i + 1
        output_name = f"{base_name}{segment_num:02d}{output_ext}"
        
        # Construct the core FFmpeg command
        ffmpeg_args = [
            FFMPEG_CMD,
            '-i', audio_path,
        ]
        
        if i < total_segments - 1:
            # All segments except the last one
            end_ms = points_ms[i+1]
            end_sec = ms_to_sec(end_ms)
            
            # Use -to for the first segment (start is implicit 0)
            if i == 0:
                 ffmpeg_args.extend([
                    '-to', end_sec,
                    '-c', 'copy',
                    output_name
                ])
                 print(f"\nSegment {segment_num} (0 to {end_sec}s) -> {output_name}")
            # Use -ss and -to for intermediate segments
            else:
                ffmpeg_args.extend([
                    '-ss', start_sec,
                    '-to', end_sec,
                    '-c', 'copy',
                    output_name
                ])
                print(f"\nSegment {segment_num} ({start_sec}s to {end_sec}s) -> {output_name}")

        else:
            # Final segment (last breakpoint to end of file)
            # Use -ss only
            ffmpeg_args.extend([
                '-ss', start_sec,
                '-c', 'copy',
                output_name
            ])
            print(f"\nSegment {segment_num} ({start_sec}s to END) -> {output_name}")
        
        # Execute the command
        if run_ffmpeg_command(ffmpeg_args):
            success_count += 1
        else:
            print(f"\n--- Stopping execution due to FFmpeg error on segment {segment_num}. ---")
            return


    print("-" * 50)
    print(f"✅ Finished splitting {audio_path} into {success_count} segments.")

# Main function to handle CLI arguments
def main():
    parser = argparse.ArgumentParser(
        description="FFmpeg Audio Splitter: Splits an audio file into multiple segments based on millisecond breakpoints provided in a text file.",
        epilog="Example usage: python cli_splitter.py 082.mp3 082.txt"
    )
    parser.add_argument(
        'audio_file',
        help='Path to the input audio file (e.g., 082.mp3).'
    )
    parser.add_argument(
        'breakpoints_file',
        help='Path to the text file containing millisecond breakpoints (one positive integer per line).'
    )
    
    args = parser.parse_args()
    
    # Quick check for FFmpeg availability
    try:
        subprocess.run([FFMPEG_CMD, '-version'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        print("\nFATAL ERROR: FFmpeg is not found in your system's PATH.")
        print("Please install FFmpeg and ensure the 'ffmpeg' command is accessible from your terminal.")
        return
        
    split_audio(args.audio_file, args.breakpoints_file)

if __name__ == "__main__":
    main()
