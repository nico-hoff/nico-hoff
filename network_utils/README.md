# Network Utilities

A comprehensive network utility tool that combines port scanning, network discovery, packet sniffing, DNS lookups, and other common network operations.

## Features

- **scan**: Scan the local network for active hosts
- **portscan**: Scan a specific host for open ports
- **netscan**: Scan well-known ports on all reachable hosts in the local network
- **sniff**: Capture and analyze network traffic
- **lookup**: Perform DNS lookups
- **trace**: Trace route to a host
- **monitor**: Monitor network performance
- **info**: Display network interface information
- **speed**: Test download/upload speeds

## Installation

### Building from source

```bash
git clone https://github.com/nicohoff/network_utils.git
cd network_utils
go build -o network_utils
```

### Requirements

- Go 1.19 or later
- External tools (optional, enhances certain features):
  - `tcpdump` (for packet sniffing)
  - `dig` (for enhanced DNS lookups)
  - `curl` (for more accurate speed tests)

## Usage

### Basic Usage

```bash
./network_utils [command] [flags]
```

### Available Commands

- `scan` - Scan the local network for active hosts
  ```bash
  ./network_utils scan
  ./network_utils scan -a -t 2  # Show all hosts with 2s timeout
  ```

- `portscan` - Scan a specific host for open ports
  ```bash
  ./network_utils portscan 192.168.1.1
  ./network_utils portscan example.com 3 -c 500 -t 2  # Scan all ports with 500 concurrent connections
  ```

- `netscan` - Scan well-known ports on all reachable hosts in local network
  ```bash
  ./network_utils netscan
  ./network_utils netscan -c 50 -p 2  # Scan with 50 concurrent hosts, 2s timeout
  ```

- `sniff` - Capture and analyze network traffic
  ```bash
  sudo ./network_utils sniff -i eth0 -p 100 -d 30 -f "port 80" -o capture.pcap
  ```

- `lookup` - Perform DNS lookups
  ```bash
  ./network_utils lookup google.com
  ./network_utils lookup google.com mx  # Look up MX records
  ```

- `trace` - Trace route to a host
  ```bash
  ./network_utils trace github.com
  ```

- `monitor` - Monitor network performance
  ```bash
  ./network_utils monitor 60 5  # Monitor for 60 seconds with 5s interval
  ```

- `speed` - Test download/upload speeds
  ```bash
  ./network_utils speed
  ```

- `info` - Display network interface information
  ```bash
  ./network_utils info
  ```

## Note on Privileges

Some commands (like `sniff`) require root/administrator privileges to work properly.

## License

MIT License 