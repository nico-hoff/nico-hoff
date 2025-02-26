#!/bin/zsh
# ping_lookup_tabular.zsh
# This script broadcasts a ping to 192.168.168.255, performs a DNS reverse lookup for each reply,
# and prints the result in a tabular format with columns for IP, Name, and Time.

# Print header row
printf "IP\tName\tTime\n"

ping -b 255.255.255.255 | while read -r line; do
    # Process only lines that contain a ping reply (look for "from")
    if [[ "$line" == *"from"* ]]; then
        # Extract the IP address from the line (assuming a "from <IP>:" pattern)
        ip=$(echo "$line" | sed -nE 's/.*from ([^:]+):.*/\1/p')
        
        # Extract the ping time (assuming a "time=<number>" pattern)
        time=$(echo "$line" | sed -nE 's/.*time=([0-9.]+) .*/\1/p')
        
        # Perform reverse DNS lookup; if it fails, default to "unknown"
        name=$(host "$ip" 2>/dev/null | sed -nE 's/.*domain name pointer (.*)/\1/p')
        if [[ -z "$name" ]]; then
            name="unknown"
        fi
        
        # Print the result in a tabular format using tabs
        printf "%s\t%s\t%s\n" "$ip" "$name" "$time"
    fi
done
