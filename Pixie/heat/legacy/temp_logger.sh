#!/bin/bash
# Log file where CSV rows will be appended
LOGFILE="/home/pi/Desktop/nico-hoff/bash_scripts/heat/data/raw/temp_log.csv"

# Ensure the CSV file has a header if it doesn't exist
if [ ! -f "$LOGFILE" ]; then
    echo "timestamp,temp" > "$LOGFILE"
fi

while true; do
    # Extract the temperature value from the 'temp1:' line and clean it up:
    # - Use awk to remove any non-numeric characters (except for minus and dot)
    temp_num=$(sensors | grep -m1 "temp1:" | awk '{gsub("[^0-9.-]", "", $2); print $2}')
    
    # Format the number as a float with one decimal using awk
    temp_float=$(awk -v num="$temp_num" 'BEGIN {printf "%.1f", num}' | tr ',' '.')
    
    # Get the current timestamp in ISO 8601 format
    timestamp=$(date --iso-8601=seconds)
    
    # Build the CSV row
    csv_row="${timestamp},${temp_float}"
    
    # Append the CSV row to the log file
    echo "$csv_row" >> "$LOGFILE"
    
    # Wait for 1 second before the next log entry
    sleep 1
done