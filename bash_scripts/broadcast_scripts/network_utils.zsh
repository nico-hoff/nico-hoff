#!/bin/zsh
# network_utils.zsh
# A comprehensive network utility script that combines port scanning, network discovery,
# packet sniffing, and other common network operations.
#
# Usage: ./network_utils.zsh <command> [options]
#
# Commands:
#   scan      - Scan the local network for active hosts
#   portscan  - Scan a specific host for open ports
#   netscan   - Scan all well-known ports on all reachable hosts in the local network
#   sniff     - Capture and analyze network traffic
#   lookup    - Perform DNS lookups
#   trace     - Trace route to a host
#   monitor   - Monitor network performance
#   info      - Display network interface information
#   speed     - Test download/upload speeds
#   help      - Display this help message

# Check for root privileges for some commands
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Some commands require root privileges. Run with sudo for full functionality."
    return 1
  fi
  return 0
}

# Helper function to print colorized output
print_colored() {
  local color=$1
  local text=$2
  
  case $color in
    "red")    echo "\033[0;31m$text\033[0m" ;;
    "green")  echo "\033[0;32m$text\033[0m" ;;
    "yellow") echo "\033[0;33m$text\033[0m" ;;
    "blue")   echo "\033[0;34m$text\033[0m" ;;
    "purple") echo "\033[0;35m$text\033[0m" ;;
    "cyan")   echo "\033[0;36m$text\033[0m" ;;
    *)        echo "$text" ;;
  esac
}

# Function to get network information
get_network_info() {
  if route -n get default 2>/dev/null | grep -q "gateway:"; then
    gateway=$(route -n get default 2>/dev/null | awk '/gateway: / {print $2}')
    interface=$(route -n get default 2>/dev/null | awk '/interface: / {print $2}')
    local_ip=$(ifconfig "$interface" 2>/dev/null | awk '/inet / {print $2; exit}')
    netmask_hex=$(ifconfig "$interface" 2>/dev/null | awk '/inet / {print $4; exit}')
    broadcast=$(ifconfig "$interface" 2>/dev/null | awk '/inet / {print $6; exit}')
    cidr=0
    hex=$(echo "$netmask_hex" | sed 's/^0[xX]//')
    for (( i=0; i<${#hex}; i++ )); do
      digit=${hex:$i:1}
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
  else
    # Fallback for Linux (Raspberry Pi / Ubuntu)
    gateway=$(ip route | awk '/default/ {print $3; exit}')
    interface=$(ip route | awk '/default/ {print $5; exit}')
    local_ip=$(ip addr show "$interface" | awk '/inet / {print $2; exit}' | cut -d'/' -f1)
    cidr=$(ip addr show "$interface" | awk '/inet / {print $2; exit}' | cut -d'/' -f2)
    broadcast=$(ip addr show "$interface" | awk '/brd/ {print $4; exit}')
    netmask_hex="N/A"
  fi
  
  network_prefix=$(echo "$local_ip" | awk -F. '{print $1"."$2"."$3}')
  num_hosts=$((2**(32-cidr)))
  
  echo "interface=$interface"
  echo "gateway=$gateway"
  echo "local_ip=$local_ip"
  echo "netmask=$netmask_hex"
  echo "broadcast=$broadcast"
  echo "cidr=$cidr"
  echo "network_prefix=$network_prefix"
  echo "num_hosts=$num_hosts"
}

# Function to display network information
cmd_info() {
  eval "$(get_network_info)"
  
  print_colored "blue" "\n=== Network Interface Information ==="
  print_colored "cyan" "Interface: $interface"
  print_colored "cyan" "IP Address: $local_ip"
  print_colored "cyan" "Default Gateway: $gateway"
  print_colored "cyan" "Network: $network_prefix.0/$cidr"
  print_colored "cyan" "Broadcast: $broadcast"
  
  print_colored "blue" "\n=== Active Interfaces ==="
  ifconfig | grep -E "^[a-z]" | awk '{print $1}' | sed 's/://' | while read -r iface; do
    if ifconfig "$iface" | grep -q "status: active"; then
      print_colored "green" "$iface (active)"
    else
      print_colored "yellow" "$iface (inactive)"
    fi
  done
  
  print_colored "blue" "\n=== Connection Statistics ==="
  netstat -i | head -1
  netstat -i | grep -E "^$interface"
}

# Function to scan network
cmd_scan() {
  local ping_timeout=1
  local show_all=0

  # Parse options
  while getopts ":t:a" opt; do
    case $opt in
      t)
        ping_timeout="$OPTARG"
        ;;
      a)
        show_all=1
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        return 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        return 1
        ;;
    esac
  done
  
  eval "$(get_network_info)"
  
  print_colored "blue" "\n=== Network Scan ==="
  print_colored "cyan" "Interface: $interface"
  print_colored "cyan" "Gateway: $gateway"
  print_colored "cyan" "Local IP: $local_ip"
  print_colored "cyan" "Network: $network_prefix.0/$cidr"
  print_colored "cyan" "Scanning $((num_hosts-2)) potential hosts...\n"
  
  # Print header for scan results
  printf "%-16s %-40s %-10s %-15s\n" "IP" "Hostname" "Response" "MAC Address"
  printf "%-16s %-40s %-10s %-15s\n" "----------------" "----------------------------------------" "----------" "---------------"
  
  # Create a tempfile to store results
  local temp_file=$(mktemp /tmp/scan_results.XXXXX)
  
  # Helper function for ping and reverse DNS lookup
  do_ping() {
    local ip="$1"
    local output=$(ping -c 1 -W "$ping_timeout" "$ip" 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
      # Extract the ping response time
      local ping_time=$(echo "$output" | sed -nE 's/.*time=([0-9.]+)[[:space:]]?ms.*/\1 ms/p')
      
      # Get hostname
      local name=$(host "$ip" 2>/dev/null | head -n 1 | sed -nE 's/.*domain name pointer (.*)/\1/p')
      
      # Get MAC address (requires ARP table entry)
      local mac=$(arp -n "$ip" 2>/dev/null | awk 'NR==2 {print $4}')
      if [[ -z "$mac" || "$mac" == "incomplete" ]]; then
        mac="unknown"
      fi
      
      # Only add hosts with known hostname or if show_all is enabled
      if [[ -n "$name" || $show_all -eq 1 ]]; then
        if [[ -z "$name" ]]; then
          name="unknown"
        elif [[ ${#name} -gt 38 ]]; then
          name="${name:0:35}..."
        fi
        
        # Write to temp file to preserve order
        echo "${ip}|${name}|${ping_time}|${mac}" >> "$temp_file"
      fi
    fi
  }
  
  # Scan network
  for (( i=1; i<num_hosts-1; i++ )); do
    ip="$network_prefix.$i"
    do_ping "$ip" &
    
    # Limit parallelism
    if (( i % 50 == 0 )); then
      wait
    fi
  done
  
  wait
  
  # Sort results by hostname ascending (case-insensitive)
  LC_ALL=C sort -t'|' -k2,2 -f "$temp_file" | while IFS="|" read -r ip name time mac; do
    printf "%-16s %-40s %-10s %-15s\n" "$ip" "$name" "$time" "$mac"
  done
  
  # Clean up
  rm -f "$temp_file"
  echo ""
}

# Function to scan ports
cmd_portscan() {
  if [[ -z "$1" ]]; then
    print_colored "red" "Error: Target IP/hostname is required."
    print_colored "yellow" "Usage: ./network_utils.zsh portscan <target IP/hostname> [port range] [options]"
    print_colored "yellow" "Port ranges: 0=Well-known(1-1024), 1=Registered(1025-49151), 2=Private(49152-65535), 3=All"
    print_colored "yellow" "Options:"
    print_colored "yellow" "  -c <concurrency> Number of concurrent port scans (default: 200)"
    print_colored "yellow" "  -t <timeout>     Connection timeout in seconds (default: 1)"
    return 1
  fi
  
  local target="$1"
  local range="${2:-0}"
  local concurrency=200
  local timeout=1
  
  # Shift the positional parameters
  shift
  if [[ -n "$1" && "$1" != -* ]]; then
    shift
  fi
  
  # Parse additional options
  while getopts ":c:t:" opt; do
    case $opt in
      c)
        concurrency="$OPTARG"
        ;;
      t)
        timeout="$OPTARG"
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        return 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        return 1
        ;;
    esac
  done
  
  # If target is a hostname, try to resolve it
  if [[ ! "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_colored "cyan" "Resolving hostname $target..."
    local resolved_ip=$(host "$target" | awk '/has address/ {print $4; exit}')
    
    if [[ -z "$resolved_ip" ]]; then
      print_colored "red" "Error: Could not resolve hostname '$target'"
      return 1
    fi
    
    print_colored "cyan" "Resolved to IP: $resolved_ip"
    local ip_target="$resolved_ip"
  else
    local ip_target="$target"
  fi
  
  # Determine port range
  case $range in
    0)
      port_start=1
      port_end=1024
      range_name="Well-known ports"
      ;;
    1)
      port_start=1025
      port_end=49151
      range_name="Registered ports"
      ;;
    2)
      port_start=49152
      port_end=65535
      range_name="Private ports"
      ;;
    3)
      port_start=1
      port_end=65535
      range_name="All ports"
      ;;
    *)
      print_colored "red" "Invalid port range. Options: 0, 1, 2, or 3"
      return 1
      ;;
  esac
  
  local total_ports=$((port_end - port_start + 1))
  
  # Lookup hostname
  local hostname=$(host "$ip_target" 2>/dev/null | sed -nE 's/.*domain name pointer (.*)/\1/p')
  if [[ -z "$hostname" ]]; then
    hostname="$target"
  fi
  
  print_colored "blue" "\n=== Port Scanner ==="
  print_colored "cyan" "Target: $target"
  if [[ "$target" != "$ip_target" ]]; then
    print_colored "cyan" "IP Address: $ip_target"
  fi
  print_colored "cyan" "Hostname: $hostname"
  print_colored "cyan" "Scanning: $range_name ($port_start-$port_end)"
  print_colored "cyan" "Total ports to scan: $total_ports"
  print_colored "cyan" "Concurrency: $concurrency\n"
  
  printf "%-8s %-20s %-30s\n" "Port" "Service" "Banner"
  printf "%-8s %-20s %-30s\n" "--------" "--------------------" "------------------------------"
  
  # ANSI colors
  local GREEN="\033[0;32m"
  local NC="\033[0m" # No Color
  
  # Common service names
  declare -A service_names=(
    [20]="FTP Data" [21]="FTP Control" [22]="SSH" [23]="Telnet" 
    [25]="SMTP" [53]="DNS" [67]="DHCP Server" [68]="DHCP Client" 
    [69]="TFTP" [80]="HTTP" [110]="POP3" [123]="NTP" 
    [137]="NetBIOS Name" [138]="NetBIOS Datagram" [139]="NetBIOS Session" 
    [143]="IMAP" [161]="SNMP" [162]="SNMP Trap" 
    [389]="LDAP" [443]="HTTPS" [445]="SMB" 
    [465]="SMTPS" [514]="Syslog" [587]="SMTP (submission)" 
    [631]="IPP" [636]="LDAPS" [993]="IMAPS" 
    [995]="POP3S" [1080]="SOCKS Proxy" [1194]="OpenVPN" 
    [1433]="MS SQL" [1723]="PPTP" [1812]="RADIUS Auth" 
    [3306]="MySQL" [3389]="RDP" [5432]="PostgreSQL" 
    [5900]="VNC" [5938]="TeamViewer" [8080]="HTTP Proxy" 
    [8443]="HTTPS Alt" [27017]="MongoDB"
  )
  
  # Temp file to store results
  local result_file=$(mktemp /tmp/port_results.XXXXX)
  
  # Helper function to scan a single port
  do_scan() {
    local port="$1"
    if nc -z -w"$timeout" "$ip_target" "$port" 2>/dev/null; then
      local service="${service_names[$port]:-unknown}"
      local banner=""
      
      # Try to get banner for common services
      if [[ "$port" -eq 22 ]]; then
        banner=$(echo "" | nc -w"$timeout" "$ip_target" "$port" 2>/dev/null | head -1 | tr -d '\r\n')
      elif [[ "$port" -eq 80 || "$port" -eq 443 || "$port" -eq 8080 || "$port" -eq 8443 ]]; then
        banner=$(echo -e "HEAD / HTTP/1.0\r\n\r\n" | nc -w"$timeout" "$ip_target" "$port" 2>/dev/null | head -1 | tr -d '\r\n')
      elif [[ "$port" -eq 21 || "$port" -eq 25 || "$port" -eq 110 || "$port" -eq 143 ]]; then
        banner=$(echo "" | nc -w"$timeout" "$ip_target" "$port" 2>/dev/null | head -1 | tr -d '\r\n')
      fi
      
      if [[ ${#banner} -gt 28 ]]; then
        banner="${banner:0:25}..."
      fi
      
      # Write result to file (port|service|banner)
      echo "$port|$service|$banner" >> "$result_file"
    fi
  }
  
  # Process a batch of ports
  process_batch() {
    local start_port=$1
    local end_port=$2
    
    for port in $(seq $start_port $end_port); do
      do_scan "$port"
    done
  }
  
  # Calculate number of ports per batch
  local batch_size=1000
  local batches=$(( (total_ports + batch_size - 1) / batch_size ))
  
  # Process in batches
  for (( batch=0; batch<batches; batch++ )); do
    local batch_start=$((port_start + batch * batch_size))
    local batch_end=$((batch_start + batch_size - 1))
    
    if (( batch_end > port_end )); then
      batch_end=$port_end
    fi
    
    # Split batch into chunks for concurrency
    local ports_in_batch=$((batch_end - batch_start + 1))
    local ports_per_process=$(( (ports_in_batch + concurrency - 1) / concurrency ))
    
    # Start concurrent processes for this batch
    for (( i=0; i<concurrency && i*ports_per_process<ports_in_batch; i++ )); do
      local chunk_start=$((batch_start + i * ports_per_process))
      local chunk_end=$((chunk_start + ports_per_process - 1))
      
      if (( chunk_end > batch_end )); then
        chunk_end=$batch_end
      fi
      
      process_batch $chunk_start $chunk_end &
    done
    
    # Wait for all processes in this batch to complete
    wait
    
    # Print progress
    if (( batch < batches-1 )); then
      local percent_done=$(( (batch+1) * 100 / batches ))
      printf "Progress: %d%% (%d/%d ports)\r" $percent_done $((batch_end+1-port_start)) $total_ports
    fi
  done
  
  # Display results sorted by port
  if [[ -s "$result_file" ]]; then
    sort -n "$result_file" | while IFS="|" read -r port service banner; do
      printf "${GREEN}%-8s %-20s %-30s${NC}\n" "$port" "$service" "$banner"
    done
  else
    print_colored "yellow" "No open ports found."
  fi
  
  # Clean up
  rm -f "$result_file"
  echo ""
}

# Function to sniff network traffic
cmd_sniff() {
  # Check if tcpdump is installed
  if ! command -v tcpdump >/dev/null 2>&1; then
    print_colored "red" "Error: tcpdump is not installed. Please install it to use this feature."
    return 1
  fi
  
  # Check for root privileges (required for packet capture)
  if ! check_root; then
    print_colored "yellow" "Warning: Running without root privileges. Some capture features may be limited."
  fi
  
  # Default values
  local iface=""
  local packet_count=100
  local duration=0
  local filter_expr=""
  local out_file=""
  
  # Parse options
  while getopts ":i:p:d:f:o:" opt; do
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
      o)
        out_file="$OPTARG"
        ;;
      \?)
        print_colored "red" "Invalid option: -$OPTARG"
        return 1
        ;;
      :)
        print_colored "red" "Option -$OPTARG requires an argument."
        return 1
        ;;
    esac
  done
  
  # If no interface specified, use the default one
  if [[ -z "$iface" ]]; then
    eval "$(get_network_info)"
    iface="$interface"
  fi
  
  print_colored "blue" "\n=== Network Sniffer ==="
  print_colored "cyan" "Interface: $iface"
  print_colored "cyan" "Packet count: $packet_count"
  if (( duration > 0 )); then
    print_colored "cyan" "Duration: $duration seconds"
  fi
  if [[ -n "$filter_expr" ]]; then
    print_colored "cyan" "Filter: $filter_expr"
  fi
  if [[ -n "$out_file" ]]; then
    print_colored "cyan" "Output file: $out_file"
  fi
  echo ""
  
  # Build tcpdump command
  local tcpdump_cmd=(tcpdump -i "$iface" -c "$packet_count" -nn)
  
  if [[ -n "$out_file" ]]; then
    tcpdump_cmd+=(-w "$out_file")
  fi
  
  if [[ -n "$filter_expr" ]]; then
    tcpdump_cmd+=("$filter_expr")
  fi
  
  # Run tcpdump with duration limit if specified
  if (( duration > 0 )); then
    if [[ -n "$out_file" ]]; then
      print_colored "green" "Capturing packets to file $out_file for $duration seconds..."
      "${tcpdump_cmd[@]}" &
      tcpdump_pid=$!
      sleep "$duration"
      kill "$tcpdump_pid" 2>/dev/null
      wait "$tcpdump_pid" 2>/dev/null
      print_colored "green" "Capture complete. File saved to: $out_file"
      
      # Show summary of captured packets
      print_colored "cyan" "\nPacket summary (first 20 packets):"
      tcpdump -r "$out_file" -nn | head -20
    else
      print_colored "green" "Capturing packets for $duration seconds..."
      "${tcpdump_cmd[@]}" &
      tcpdump_pid=$!
      sleep "$duration"
      kill "$tcpdump_pid" 2>/dev/null
      wait "$tcpdump_pid" 2>/dev/null
    fi
  else
    print_colored "green" "Starting packet capture..."
    "${tcpdump_cmd[@]}"
  fi
}

# Function to scan well-known ports on all reachable hosts in the local network
cmd_netscan() {
  local concurrency=100
  local ping_timeout=1
  local port_timeout=1
  local show_all=0

  # Parse options
  while getopts ":c:t:p:a" opt; do
    case $opt in
      c)
        concurrency="$OPTARG"
        ;;
      t)
        ping_timeout="$OPTARG"
        ;;
      p)
        port_timeout="$OPTARG"
        ;;
      a)
        show_all=1
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        return 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        return 1
        ;;
    esac
  done
  
  print_colored "blue" "\n=== Network-wide Port Scanner ==="
  print_colored "cyan" "Scanning all reachable hosts for well-known ports (1-1024)"
  print_colored "cyan" "Concurrency: $concurrency (hosts scanned in parallel)"
  print_colored "cyan" "Port timeout: $port_timeout seconds"
  
  # Create temporary files
  local hosts_file=$(mktemp /tmp/netscan_hosts.XXXXX)
  local results_file=$(mktemp /tmp/netscan_results.XXXXX)
  
  # First perform a network scan to find all active hosts
  print_colored "green" "\nPhase 1: Discovering active hosts on the network..."
  
  eval "$(get_network_info)"
  
  # Ping scan the network to find active hosts
  for (( i=1; i<num_hosts-1; i++ )); do
    ip="$network_prefix.$i"
    ping -c 1 -W "$ping_timeout" "$ip" > /dev/null 2>&1 &
    
    # Limit parallelism
    if (( i % 50 == 0 )); then
      wait
    fi
  done
  
  wait
  
  # Get the list of responsive hosts from ARP table
  arp -a | grep -v "incomplete" | awk '{print $2}' | tr -d '()' > "$hosts_file"
  
  local host_count=$(wc -l < "$hosts_file")
  print_colored "green" "Found $host_count active hosts"
  
  # Exit if no hosts found
  if [[ $host_count -eq 0 ]]; then
    print_colored "red" "No active hosts found. Exiting."
    rm -f "$hosts_file" "$results_file"
    return 1
  fi
  
  # Phase 2: Scan each host for open ports
  print_colored "green" "\nPhase 2: Scanning each host for well-known ports (1-1024)..."
  print_colored "yellow" "This may take some time depending on the number of hosts."
  
  # Function to scan a single host
  scan_host() {
    local host="$1"
    local temp_file=$(mktemp /tmp/host_scan.XXXXX)
    
    # Use the existing portscan function but redirect output to a file
    (
      echo "=== Host: $host ===" >> "$temp_file"
      # Invoke the portscan function with range 0 (well-known ports)
      cmd_portscan "$host" 0 -c "$concurrency" -t "$port_timeout" | grep -v "Scanning\|Progress\|Target\|Port ranges\|Options\|Total ports" >> "$temp_file"
    )
    
    # Append results to the global results file
    cat "$temp_file" >> "$results_file"
    rm -f "$temp_file"
  }
  
  # Read hosts file and scan each host with limited concurrency
  local host_count=0
  local total_hosts=$(wc -l < "$hosts_file")
  
  cat "$hosts_file" | while read -r host; do
    # Launch scan in background
    scan_host "$host" &
    
    # Update counter
    host_count=$((host_count + 1))
    
    # Print progress
    printf "Progress: %d%% (%d/%d hosts)\r" $((host_count * 100 / total_hosts)) $host_count $total_hosts
    
    # Limit number of concurrent host scans
    if (( host_count % concurrency == 0 )); then
      wait
    fi
  done
  
  # Wait for all background processes to finish
  wait
  
  print_colored "green" "\nScan complete. Results:"
  print_colored "yellow" "\n=== Network-wide Port Scan Results ==="
  cat "$results_file"
  
  # Clean up
  rm -f "$hosts_file" "$results_file"
}

# Function to perform DNS lookups
cmd_lookup() {
  if [[ -z "$1" ]]; then
    print_colored "red" "Error: Target host/IP is required."
    print_colored "yellow" "Usage: ./network_utils.zsh lookup <hostname/IP> [type]"
    print_colored "yellow" "Types: a, mx, ns, txt, soa, any (default: a)"
    return 1
  fi
  
  local target="$1"
  local type="${2:-a}"
  local type_upper=$(echo "$type" | tr '[:lower:]' '[:upper:]')
  
  print_colored "blue" "\n=== DNS Lookup ==="
  print_colored "cyan" "Target: $target"
  print_colored "cyan" "Record type: $type_upper\n"
  
  # Standard lookup
  print_colored "yellow" "Standard Lookup:"
  host -t "$type" "$target"
  
  # Reverse lookup if IP
  if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_colored "yellow" "\nReverse Lookup:"
    host "$target"
  fi
  
  # Additional information if dig is available
  if command -v dig >/dev/null 2>&1; then
    print_colored "yellow" "\nDetailed Information (dig):"
    dig "$target" "$type" +short
  fi
}

# Function to trace route to a host
cmd_trace() {
  if [[ -z "$1" ]]; then
    print_colored "red" "Error: Target host/IP is required."
    print_colored "yellow" "Usage: ./network_utils.zsh trace <hostname/IP>"
    return 1
  fi
  
  local target="$1"
  
  print_colored "blue" "\n=== Traceroute ==="
  print_colored "cyan" "Target: $target\n"
  
  # Run traceroute and process the output directly
  traceroute "$target" | while read -r line; do
    if [[ "$line" == *"ms"* ]]; then
      # Print the line directly (without trying to process with sed)
      echo "$line"
    else
      echo "$line"
    fi
  done
}

# Function to monitor network performance
cmd_monitor() {
  local duration=${1:-30}
  local interval=${2:-1}
  
  print_colored "blue" "\n=== Network Performance Monitor ==="
  print_colored "cyan" "Duration: $duration seconds"
  print_colored "cyan" "Sampling interval: $interval seconds\n"
  
  # Get initial stats
  eval "$(get_network_info)"
  local start_time=$(date +%s)
  local end_time=$((start_time + duration))
  
  # Get initial packet counts using netstat
  local initial_stats=$(netstat -I "$interface")
  local initial_in=$(echo "$initial_stats" | awk 'NR==2 {print $5}')
  local initial_out=$(echo "$initial_stats" | awk 'NR==2 {print $7}')
  
  if [[ -z "$initial_in" || -z "$initial_out" ]]; then
    print_colored "red" "Error: Could not determine interface statistics for $interface"
    return 1
  fi
  
  # Print header
  printf "%-20s %-15s %-15s %-15s %-15s\n" "Timestamp" "In (pkts/s)" "Out (pkts/s)" "Total In (pkts)" "Total Out (pkts)"
  printf "%-20s %-15s %-15s %-15s %-15s\n" "--------------------" "---------------" "---------------" "---------------" "---------------"
  
  # Monitor loop
  while [[ $(date +%s) -lt $end_time ]]; do
    # Sleep for the interval
    sleep "$interval"
    
    # Get current timestamp
    local current_time=$(date +"%H:%M:%S")
    
    # Get current packet counts
    local current_stats=$(netstat -I "$interface")
    local current_in=$(echo "$current_stats" | awk 'NR==2 {print $5}')
    local current_out=$(echo "$current_stats" | awk 'NR==2 {print $7}')
    
    # Calculate rates (packets per second)
    local in_rate=$(( (current_in - initial_in) / interval ))
    local out_rate=$(( (current_out - initial_out) / interval ))
    
    # Print results
    printf "%-20s %-15s %-15s %-15s %-15s\n" "$current_time" "$in_rate" "$out_rate" "$current_in" "$current_out"
    
    # Update initial values for next iteration
    initial_in=$current_in
    initial_out=$current_out
  done
}

# Function to test download/upload speeds
cmd_speed() {
  print_colored "blue" "\n=== Network Speed Test ==="
  
  # Check if curl is installed
  if ! command -v curl >/dev/null 2>&1; then
    print_colored "red" "Error: curl is not installed. Please install it to use this feature."
    return 1
  fi
  
  # Test files of different sizes
  local sizes=("10MB" "100MB")
  local test_urls=(
    "http://speedtest.ftp.otenet.gr/files/test10Mb.db"
    "http://speedtest.ftp.otenet.gr/files/test100Mb.db"
  )
  
  # Use 1-indexed loop for zsh arrays
  for i in {1..2}; do
    local size="${sizes[$i]}"
    local url="${test_urls[$i]}"
    
    print_colored "cyan" "\nTesting download speed (${size} file)..."
    local start_time=$(date +%s.%N)
    curl -s -o /dev/null "$url" &
    curl_pid=$!
    
    # Show progress
    local elapsed=0
    while kill -0 $curl_pid 2>/dev/null; do
      elapsed=$(echo "$(date +%s.%N) - $start_time" | LC_ALL=C bc -l)
      printf "\rDownloading... %.1f seconds elapsed" "$elapsed"
      sleep 0.5
    done
    
    local end_time=$(date +%s.%N)
    local download_time=$(echo "$end_time - $start_time" | LC_ALL=C bc -l)
    
    # Prevent division by zero
    if (( $(echo "$download_time <= 0" | LC_ALL=C bc -l) )); then
      download_time=0.001
    fi
    
    # Calculate speed in Mbps
    local size_mb=${size%MB}
    local speed_mbps=$(echo "scale=2; $size_mb * 8 / $download_time" | LC_ALL=C bc -l)
    
    printf "\rDownload speed: \033[0;32m%.2f Mbps\033[0m (%.2f seconds)                   \n" "$speed_mbps" "$download_time"
    
    # Exit after first test if it takes too long
    if (( $(echo "$download_time > 10" | LC_ALL=C bc -l) )); then
      break
    fi
  done
  
  # Print ping statistics to common servers
  print_colored "cyan" "\nPing statistics:"
  for server in "8.8.8.8" "1.1.1.1" "208.67.222.222"; do
    ping -c 3 "$server" 2>/dev/null | grep "avg" | sed "s/.*= //g" | sed "s/\//, /g" | awk '{print "  '$server': min/avg/max = "$1"/"$2"/"$3" ms"}'
  done
}

# Display help
cmd_help() {
  cat << EOF
$(print_colored "blue" "Network Utilities Script")
$(print_colored "blue" "========================")

A comprehensive network utility script that combines port scanning, network discovery,
packet sniffing, and other common network operations.

$(print_colored "yellow" "Usage:") 
  ./network_utils.zsh <command> [options]

$(print_colored "yellow" "Commands:")
  scan      - Scan the local network for active hosts
             Options: 
             -t <timeout> (ping timeout in seconds, default: 1)
             -a (show all hosts, even without hostname)

  portscan  - Scan a specific host for open ports
             Usage: portscan <target IP/hostname> [port range]
             Port ranges: 0=Well-known(1-1024), 1=Registered(1025-49151), 
                         2=Private(49152-65535), 3=All
             Options:
             -c <concurrency> (number of concurrent port scans, default: 200)
             -t <timeout> (connection timeout in seconds, default: 1)
             
  netscan   - Scan all well-known ports on all reachable hosts in local network
             Options:
             -c <concurrency> (number of hosts to scan in parallel, default: 100)
             -t <timeout> (host discovery timeout in seconds, default: 1)
             -p <timeout> (port scan timeout in seconds, default: 1)
             -a (show all hosts, even without hostname)

  sniff     - Capture and analyze network traffic
             Options: -i <interface> -p <packet_count> -d <duration> 
                     -f <filter_expression> -o <output_file>

  lookup    - Perform DNS lookups
             Usage: lookup <hostname/IP> [type]
             Types: a, mx, ns, txt, soa, any (default: a)

  trace     - Trace route to a host
             Usage: trace <hostname/IP>

  monitor   - Monitor network performance
             Usage: monitor [duration in seconds] [sampling interval]

  speed     - Test download/upload speeds

  info      - Display network interface information

  help      - Display this help message

$(print_colored "yellow" "Examples:")
  ./network_utils.zsh scan
  ./network_utils.zsh scan -a               # Show all hosts, even without hostname
  ./network_utils.zsh portscan 192.168.1.1 0
  ./network_utils.zsh portscan google.com 0 -c 500
  ./network_utils.zsh netscan -c 50         # Scan all hosts with 50 hosts in parallel
  ./network_utils.zsh netscan -p 2          # Use 2 seconds timeout for port scanning
  ./network_utils.zsh sniff -i en0 -p 100 -d 30 -f "port 80" -o capture.pcap
  ./network_utils.zsh lookup google.com mx
  ./network_utils.zsh trace github.com
  ./network_utils.zsh monitor 60 5
  ./network_utils.zsh speed
  ./network_utils.zsh info

EOF
}

# Main function to handle command dispatch
main() {
  local cmd="$1"
  shift
  
  case "$cmd" in
    "scan")      cmd_scan "$@" ;;
    "portscan")  cmd_portscan "$@" ;;
    "netscan")   cmd_netscan "$@" ;;
    "sniff")     cmd_sniff "$@" ;;
    "lookup")    cmd_lookup "$@" ;;
    "trace")     cmd_trace "$@" ;;
    "monitor")   cmd_monitor "$@" ;;
    "speed")     cmd_speed "$@" ;;
    "info")      cmd_info "$@" ;;
    "help"|"-h"|"--help") cmd_help ;;
    *)
      if [[ -z "$cmd" ]]; then
        cmd_help
      else
        print_colored "red" "Unknown command: $cmd"
        print_colored "yellow" "Run './network_utils.zsh help' for usage information."
      fi
      ;;
  esac
}

# Run main function with all arguments
main "$@"