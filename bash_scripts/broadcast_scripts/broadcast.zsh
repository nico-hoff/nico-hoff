#!/bin/zsh
# network_scan.zsh
# This script scans the local network (192.168.178.0/24) by pinging each host,
# performs a reverse DNS lookup for each that responds,
# and prints the results in a tabular format: IP, Name, Time.

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

# Print router IP and network characteristics
printf "Router IP: %s\n" "$gateway"
if command -v ipcalc >/dev/null; then
    ipcalc "$local_ip/$cidr"
else
    printf "Network: %s.0, CIDR: /%s\n" "$network_prefix" "$cidr"
fi

# Print header for scan results
printf "\nIP\tName\tTime\n"

# Helper function for ping and reverse DNS lookup (runs in background)
do_ping() {
    ip="$1"
    output=$(ping -c 1 -W 1 "$ip" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        ping_time=$(echo "$output" | sed -nE 's/.*time=([0-9.]+).*/\1/p')
        name=$(host "$ip" 2>/dev/null | sed -nE 's/.*domain name pointer (.*)/\1/p')
        if [[ -z "$name" ]]; then
            name="unknown"
        fi
        printf "%s\t%s\t%s\n" "$ip" "$name" "$ping_time"
    fi
}

# Loop over IP addresses concurrently using the computed network prefix (assuming /24)
for i in {1..254}; do
    ip="$network_prefix.$i"
    do_ping "$ip" &
done
wait
