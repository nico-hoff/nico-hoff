#!/bin/bash
# Log file where JSON objects will be appended
LOGFILE="./temp_log.json"

while true; do
    # Extract the temperature value from the 'temp1:' line and clean it up:
    # - Use awk to remove any non-numeric characters (except for minus and dot)
    temp_num=$(sensors | grep -m1 "temp1:" | awk '{gsub("[^0-9.-]", "", $2); print $2}')
    
    # Format the number as a float with one decimal using awk
    temp_float=$(awk -v num="$temp_num" 'BEGIN {printf "%.1f", num}')
    
    # Get the current timestamp in ISO 8601 format
    timestamp=$(date --iso-8601=seconds)
    
    # Build the JSON object including a measure_type field.
    json="{\"timestamp\": \"${timestamp}\", \"temp\": ${temp_float}, \"measure_type\": \"temperature\"}"
    
    # Append the JSON object to the log file
    echo "$json" >> "$LOGFILE"
    
    # Wait for 5 seconds before the next log entry
    sleep 5
done
