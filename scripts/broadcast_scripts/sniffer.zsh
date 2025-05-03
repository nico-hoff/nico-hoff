#!/bin/zsh
# sniffer.zsh
# This script is a sophisticated network sniffer using tcpdump.
# It captures network packets on a specified interface and supports options
# for packet count, capture duration, and custom filter expressions.
#
# Usage: ./sniffer.zsh -i <interface> [-p <packet_count>] [-d <duration_seconds>] [-f <filter_expression>]
#
# Detailed Explanation:
# - The "-i" flag specifies the network interface to sniff (e.g., en0).
# - The "-p" flag (optional) sets the number of packets to capture (default: 100).
# - The "-d" flag (optional) sets the capture duration in seconds (default: 5).
# - The "-f" flag (optional) allows a custom tcpdump filter expression (default: capture all).

# Check if tcpdump is installed
if ! command -v tcpdump >/dev/null 2>&1; then
    echo "tcpdump is not installed. Please install tcpdump to use this script."
    exit 1
fi

# Default values
packet_count=100       # Default number of packets to capture
duration=0             # Duration in seconds (0 means no duration limit)
filter_expr=""         # Default filter expression (empty means capture all)

# Parse command-line arguments
while getopts ":i:p:d:f:" opt; do
  case $opt in
    i)
      iface="$OPTARG"
      ;;
    p)
      packet_count="$OPTARG"
      ;;
    d)
      duration="$OPTARG"
      ;;
    f)
      filter_expr="$OPTARG"
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

# Ensure the interface parameter was provided
if [[ -z "$iface" ]]; then
    echo "Usage: $0 -i <interface> [-p <packet_count>] [-d <duration_seconds>] [-f <filter_expression>]"
    exit 1
fi

# Build tcpdump command with provided parameters.
# - "-i" specifies the interface.
# - "-c" limits the number of packets.
# - "$filter_expr" applies the custom filter if provided.
if (( duration > 0 )); then
    # Create a temporary file for capture output
    tmpfile=$(mktemp /tmp/sniffer.XXXXX.pcap)
    echo "Capturing packets on interface '$iface' to file..."

    # Build tcpdump command with -w for file output
    tcpdump_cmd=(tcpdump -i "$iface" -c "$packet_count" -w "$tmpfile")
    if [[ -n "$filter_expr" ]]; then
        tcpdump_cmd+=($filter_expr)
    fi

    # Run tcpdump in background and kill after the duration expires
    "${tcpdump_cmd[@]}" &
    tcpdump_pid=$!
    echo "Sniffing for $duration seconds..."
    sleep "$duration"
    kill "$tcpdump_pid" 2>/dev/null
    wait "$tcpdump_pid" 2>/dev/null

    # Process captured file
    echo "Capture complete. Output stored in: $tmpfile"
    echo "Processing captured packets for summary..."
    tcpdump -r "$tmpfile" | head -20

    # Clean up temporary file
    rm "$tmpfile"
    echo "Temporary capture file removed."
else
    # Duration is 0: stream tcpdump output directly to console (remove -w)
    echo "Streaming capture output to console..."
    tcpdump_cmd=(tcpdump -i "$iface" -c "$packet_count")
    if [[ -n "$filter_expr" ]]; then
        tcpdump_cmd+=($filter_expr)
    fi
    "${tcpdump_cmd[@]}"
fi

# End of script
