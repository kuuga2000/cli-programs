#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_file> <breakdown_numbers...>"
    echo "Example: $0 082.mp3 7090 11610 17350"
    exit 1
fi

input_file="$1"
shift
breakdowns=("$@")

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found!"
    exit 1
fi

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed!"
    exit 1
fi

# Get filename without extension
filename=$(basename "$input_file" .mp3)

echo "Processing: $input_file"
echo "Breakdown points: ${breakdowns[@]}"
echo "=============================================="

# Generate and execute commands for each breakdown
counter=1
for ms in "${breakdowns[@]}"; do
    # Convert milliseconds to seconds
    seconds=$(echo "scale=2; $ms / 1000" | bc)
    
    # Generate output filename with leading zeros
    part_num=$(printf "%02d" $counter)
    output_file="${filename}${part_num}.mp3"
    
    echo "Creating segment $counter: $output_file (${seconds}s)"
    
    # Execute FFmpeg command
    ffmpeg -i "$input_file" -t "$seconds" -c copy "$output_file" -y
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully created: $output_file"
    else
        echo "✗ Failed to create: $output_file"
    fi
    
    echo "---"
    counter=$((counter + 1))
done

echo "All segments processed!"