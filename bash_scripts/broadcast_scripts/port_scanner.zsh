#!/bin/zsh
# port_scanner.zsh
# This script scans ports (1-1024) on a given IP and attempts to detect services.

if [[ -z "$1" ]]; then
    echo "Usage: $0 <target IP>"
    exit 1
fi
target="$1"
printf "Scanning ports on %s...\n" "$target"
printf "Port\tService\n"

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
        printf "%s\t%s\n" "$port" "$service"
    fi
}

# Limit concurrency to avoid spawning too many background tasks
concurrency=100
count=0
for port in {1..1024}; do
    do_scan "$port" &
    count=$((count+1))
    if (( count % concurrency == 0 )); then
        wait
    fi
done
wait
