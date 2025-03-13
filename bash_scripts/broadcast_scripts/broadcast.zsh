#!/bin/zsh
# network_scan.zsh
# This script scans the local network (192.168.178.0/24) by pinging each host,
# performs a reverse DNS lookup for each that responds,
# and prints the results in a tabular format: IP, Name, Time.
#
# Usage: ./broadcast.zsh [-t <ping_timeout>] 
# (Other parameters are auto-detected; use -t to override the ping timeout in seconds)
#
# Detailed Explanation:
# - The "-t" flag (optional) sets the ping timeout in milliseconds (default: 1).
# - The script auto-detects the local network, prints the router and caller IP,
#   and scans hosts concurrently.

# Detect default gateway and network interface (macOS compatible)
gateway=$(route -n get default 2>/dev/null | awk '/gateway: / {print $2}')
interface=$(route -n get default 2>/dev/null | awk '/interface: / {print $2}')

# Extract local IP, netmask (hex), and broadcast from ifconfig
local_ip=$(ifconfig "$interface" 2>/dev/null | awk '/inet / {print $2; exit}')
netmask_hex=$(ifconfig "$interface" 2>/dev/null | awk '/inet / {print $4; exit}')
broadcast=$(ifconfig "$interface" 2>/dev/null | awk '/inet / {print $6; exit}')

# Convert hex netmask to CIDR notation
cidr=0
# Remove 0x or 0X prefix
hex=$(echo "$netmask_hex" | sed 's/^0[xX]//')
for (( i=0; i<${#hex}; i++ )); do
    digit=${hex:$i:1}
    # Convert hex digit to binary string using printf
    binary=$(printf "%04d" "$(echo "ibase=16; obase=10; $(printf "%d" "0x$digit")" | bc)")
    # Alternative way: convert hex digit to integer and use a lookup table
    case "$digit" in
      [Ff]) bits=4 ;;
      [Ee]) bits=3 ;;
      [Dd]) bits=3 ;;
      [Cc]) bits=2 ;;
      [Bb]) bits=3 ;;
      [Aa]) bits=2 ;;
      [9]) bits=2 ;;
      [8]) bits=1 ;;
      [7]) bits=3 ;;
      [6]) bits=2 ;;
      [5]) bits=2 ;;
      [4]) bits=1 ;;
      [3]) bits=2 ;;
      [2]) bits=1 ;;
      [1]) bits=1 ;;
      [0]) bits=0 ;;
      *) bits=0 ;;
    esac
    cidr=$((cidr+bits))
done

# Fallback: if local_ip empty, use broadcast address (example: 255.255.255.255)
if [[ -z "$local_ip" ]]; then
    local_ip="255.255.255.255"
    cidr=32
fi

# Compute network prefix (assumes IPv4; using first three octets for a /24)
network_prefix=$(echo "$local_ip" | awk -F. '{print $1"."$2"."$3}')

# Default ping timeout (in milliseconds)
ping_timeout=10000

# Parse any custom flag for ping timeout
while getopts ":t:" opt; do
  case $opt in
    t)
      ping_timeout="$OPTARG" * 1000
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Print router IP and network characteristics
printf "\n"
printf "Network Interface: %s\n" "$interface"
printf "Default Gateway: %s\n" "$gateway"
printf "Caller IP: %s\n" "$local_ip"
if command -v ipcalc >/dev/null; then
    ipcalc "$local_ip/$cidr"
else
    printf "Network: %s.0, CIDR: /%s\n" "$network_prefix" "$cidr"
fi

# Print header for scan results (cleaner table format)
printf "\n%-20s %-35s %-8s\n" "IP" "Name" "Time"

# Helper function for ping and reverse DNS lookup (runs in background)
do_ping() {
    ip="$1"
    output=$(ping -c 1 -W "$ping_timeout" "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        # Extract the ping response time (e.g., "3.235 ms") from output
        ping_time=$(echo "$output" | sed -nE 's/.*time=([0-9.]+)[[:space:]]?ms.*/\1 ms/p')
        name=$(host "$ip" 2>/dev/null | head -n 1 | sed -nE 's/.*domain name pointer (.*)/\1/p')
        if [[ -n "$name" ]]; then
            name=$(echo "$name" | tr '\n' ' and ')
        fi

        if [[ -z "$name" ]]; then
            name="unknown"
        else
            # Truncate name if longer than 13 characters and add "..."
            if [[ ${#name} -gt 30 ]]; then
              name="${name:0:27}..."
            fi
        fi
        # Print row with fixed-width columns
        printf "%-20s %-35s %-8s\n" "$ip" "$name" "$ping_time"

    fi
}

# Loop over IP addresses concurrently using the computed network prefix (assuming /24)
for i in {1..254}; do
    ip="$network_prefix.$i"
    do_ping "$ip" &
done
wait

