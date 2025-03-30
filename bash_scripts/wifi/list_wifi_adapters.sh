#!/bin/bash

echo "[+] Detecting Wi-Fi adapters..."

# Get all network interfaces
network_info=$(networksetup -listallhardwareports)

# Parse and format output
echo -e "\n🔍 Available Wi-Fi Interfaces:"
echo "-------------------------------------------"

current_port=""
while IFS= read -r line; do
    if [[ $line == "Hardware Port: Wi-Fi"* ]]; then
        current_port=$(echo "$line" | awk -F": " '{print $2}')
    elif [[ $line == "Device:"* ]] && [[ -n $current_port ]]; then
        device=$(echo "$line" | awk -F": " '{print $2}')
        mac=$(ifconfig $device | awk '/ether/ {print $2}')
        status=$(ifconfig $device | grep -q "status: active" && echo "🟢 Connected" || echo "🔴 Not Connected")
        
        echo -e "🌐 Interface: $device"
        echo -e "🔢 MAC Addr : $mac"
        echo -e "📡 Status   : $status"
        echo "-------------------------------------------"

        # Reset for next Wi-Fi adapter
        current_port=""
    fi
done <<< "$network_info"