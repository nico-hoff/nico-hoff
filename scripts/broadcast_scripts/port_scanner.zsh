#!/bin/zsh
# port_scanner.zsh
# This script scans ports on a given IP and attempts to detect services.

if [[ -z "$1" ]]; then
    echo "\nUsage: ./port_scanner.zsh <target IP> [port range: int0-2]\n"
    echo "   0: Well Known Ports\n   1: Registered Ports\n   2: Private Ports\n"
    exit 1
fi
target="$1"
range="${2:-0}"

# Determine port range based on second argument ($2), default to "low"
case $range in
    0)
        port_start=1
        port_end=1024
        ;;
    1)
        port_start=1025
        port_end=49151
        ;;
    2)
        port_start=49152
        port_end=65535
        ;;
    *)
        echo "Invalid port range. Options: low, mid, high"
        exit 1
        ;;
esac

total_ports=$((port_end - port_start + 1))
printf "\nScanning ports on %s" "$target"

# Perform a reverse DNS lookup to get the hostname of the target IP
hostname=$(host "$target" 2>/dev/null | sed -nE 's/.*domain name pointer (.*)/\1/p')
if [[ -z "$hostname" ]]; then
    hostname="unknown"
fi
printf "\nTarget Host: %s" "$hostname"

# Table header remains fixed
printf "\nIn Port Range: %s-%s (%s ports)\n" "$port_start" "$port_end" "$total_ports"

printf "\n   Port\tService\n"

# Helper function to scan a single port
do_scan() {
    port="$1"
    nc -z -w1 "$target" "$port" 2>/dev/null 1>/dev/null
    if [[ $? -eq 0 ]]; then
        case "$port" in
            21) service="FTP" ;;
            22) service="SSH" ;;
            23) service="Telnet" ;;
            25) service="SMTP" ;;
            53) service="DNS" ;;
            80) service="HTTP" ;;
            110) service="POP3" ;;
            143) service="IMAP" ;;
            443) service="HTTPS" ;;
            993) service="IMAPS" ;;
            995) service="POP3S" ;;
            *) service="unknown" ;;
        esac
        printf "   %s\t%s\n" "$port" "$service"
    fi
}

# Limit concurrency to avoid spawning too many background tasks
concurrency=100
count=0
for port in $(seq $port_start $port_end); do
    do_scan "$port" &
    count=$((count+1))
    if (( count % concurrency == 0 )); then
        wait
    fi
done
wait

printf "\n"