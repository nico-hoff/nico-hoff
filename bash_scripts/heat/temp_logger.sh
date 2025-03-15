#!/bin/bash

# Use absolute path, normalized to remove double slashes
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="${SCRIPT_DIR}/data/raw/temp_log_multi.csv"

# Create directory if it doesn't exist
target_dir=$(dirname "$LOGFILE")
mkdir -p "$target_dir"

# Ensure the CSV file has a header if it doesn't exist
if [ ! -f "$LOGFILE" ]; then
    # Updated header: only timestamp, temp, and avg_mhz
    header="timestamp,temp,avg_mhz"
    echo "$header" > "$LOGFILE"
fi

while true; do
    # Get temperature
    temp_num=$(sensors | grep -m1 "temp1:" | awk '{gsub("[^0-9.-]", "", $2); print $2}')
    temp_float=$(awk -v num="$temp_num" 'BEGIN {printf "%.1f", num}' | tr ',' '.')
    
    # Get current timestamp
    timestamp=$(date --iso-8601=seconds)
    
    # Start building CSV row
    csv_row="${timestamp},${temp_float}"
    
    # Get CPU frequencies from lscpu output (one per core)
    declare -a freqs
    mapfile -t freqs < <(lscpu -e=MHz | tail -n +2)
    
    # Calculate average MHz across all cores
    core_count=${#freqs[@]}
    total=0
    for freq in "${freqs[@]}"; do
        total=$(awk -v t="$total" -v f="$freq" 'BEGIN {printf "%.1f", t+f}' | tr ',' '.')
    done
    avg_mhz=$(awk -v total="$total" -v count="$core_count" 'BEGIN {printf "%.1f", total/count}' | tr ',' '.')
    
    # Append average MHz to CSV row
    csv_row="${csv_row},${avg_mhz}"
    
    # Append the CSV row to the log file
    echo "$csv_row" >> "$LOGFILE"
    
    sleep 3
done