#!/bin/zsh
# async_network_scan.zsh
# This script scans the 192.168.178.0/24 network asynchronously.
# For each responsive host, it performs a reverse DNS lookup and
# prints the results (IP, Name, Time) in a neatly aligned table.

# Create a temporary file to store results
tempfile=$(mktemp)

# Loop over IP addresses 192.168.178.1 to 192.168.178.254
for i in {1..254}; do
    ip="192.168.178.$i"
    {
        # Ping each IP once, with a timeout of 1 second
        output=$(ping -c 1 -W 1 "$ip" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            # Extract the ping time (assumes output contains "time=XX")
            ping_time=$(echo "$output" | sed -nE 's/.*time=([0-9.]+).*/\1/p')
            
            # Perform reverse DNS lookup; if none found, use "unknown"
            name=$(host "$ip" 2>/dev/null | sed -nE 's/.*domain name pointer (.*)/\1/p')
            if [[ -z "$name" ]]; then
                name="unknown"
            fi
            
            # Write the result as a single tab-separated line to the temporary file
            printf "%s\t%s\t%s\n" "$ip" "$name" "$ping_time" >> "$tempfile"
        fi
    } &
done

# Wait for all background ping jobs to finish
wait

# Print header and then the results formatted in a table.
{
    printf "IP\tName\tTime\n"
    cat "$tempfile"
} | column -t -s $'\t'

# Clean up temporary file
rm "$tempfile"
