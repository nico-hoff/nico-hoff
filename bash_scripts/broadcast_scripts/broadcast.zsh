#!/bin/zsh
# network_scan.zsh
# This script scans the local network (192.168.178.0/24) by pinging each host,
# performs a reverse DNS lookup for each that responds,
# and prints the results in a tabular format: IP, Name, Time.

# Print header
printf "IP\tName\tTime\n"

# Loop over IP addresses 192.168.178.1 to 192.168.178.254
for i in {1..254}; do
    ip="$1.$i"
    # Ping once with a timeout of 1 second
    output=$(ping -c 1 -W 1 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        # Extract the ping time (assumes output contains "time=XX" )
        ping_time=$(echo "$output" | sed -nE 's/.*time=([0-9.]+).*/\1/p')
        
        # Perform reverse DNS lookup; if it fails, set name to "unknown"
        name=$(host "$ip" 2>/dev/null | sed -nE 's/.*domain name pointer (.*)/\1/p')
        if [[ -z "$name" ]]; then
            name="unknown"
        fi
        
        # Print the result in tabular format
        printf "%s\t%s\t%s\n" "$ip" "$name" "$ping_time"
    fi
done
