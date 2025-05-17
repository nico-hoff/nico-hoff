package utils

import (
	"fmt"
	"net"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/fatih/color"
)

// NetworkInfo stores information about the local network
type NetworkInfo struct {
	Interface     string
	Gateway       string
	LocalIP       string
	Netmask       string
	Broadcast     string
	CIDR          int
	NetworkPrefix string
	NumHosts      int
}

// GetNetworkInfo retrieves information about the local network
func GetNetworkInfo() (*NetworkInfo, error) {
	// Find the default interface
	ifaces, err := net.Interfaces()
	if err != nil {
		return nil, err
	}

	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue // Skip down or loopback interfaces
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			ipNet, ok := addr.(*net.IPNet)
			if !ok || ipNet.IP.To4() == nil {
				continue // Skip non-IPv4 addresses
			}

			// We've found an interface with an IPv4 address
			// Let's calculate the network information
			ip := ipNet.IP.To4()
			mask := ipNet.Mask
			cidr, _ := mask.Size()
			gateway := getDefaultGateway()

			// Calculate the network prefix
			networkIP := ip.Mask(mask)
			networkPrefix := fmt.Sprintf("%d.%d.%d", networkIP[0], networkIP[1], networkIP[2])

			// Calculate broadcast address
			broadcast := calculateBroadcast(ip, mask)

			return &NetworkInfo{
				Interface:     iface.Name,
				Gateway:       gateway,
				LocalIP:       ip.String(),
				Netmask:       fmt.Sprintf("%d.%d.%d.%d", mask[0], mask[1], mask[2], mask[3]),
				Broadcast:     broadcast,
				CIDR:          cidr,
				NetworkPrefix: networkPrefix,
				NumHosts:      1 << (32 - cidr),
			}, nil
		}
	}

	return nil, fmt.Errorf("no active network interface found")
}

// getDefaultGateway tries to retrieve the default gateway
func getDefaultGateway() string {
	// Try different methods to get the default gateway
	// This is very OS-specific and might need adjustments
	cmd := exec.Command("ip", "route", "show", "default")
	output, err := cmd.Output()
	if err == nil {
		parts := strings.Fields(string(output))
		if len(parts) >= 3 {
			return parts[2]
		}
	}

	// Fallback to 'route' command
	cmd = exec.Command("route", "-n")
	output, err = cmd.Output()
	if err == nil {
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			fields := strings.Fields(line)
			if len(fields) >= 8 && fields[0] == "0.0.0.0" {
				return fields[1]
			}
		}
	}

	return "unknown"
}

// calculateBroadcast calculates the broadcast address from an IP and netmask
func calculateBroadcast(ip net.IP, mask net.IPMask) string {
	ip = ip.To4()
	if ip == nil {
		return "unknown"
	}

	broadcast := make(net.IP, len(ip))
	for i := 0; i < len(ip); i++ {
		broadcast[i] = ip[i] | ^mask[i]
	}

	return broadcast.String()
}

// IsRoot checks if the program is running with root privileges
func IsRoot() bool {
	cmd := exec.Command("id", "-u")
	output, err := cmd.Output()
	if err != nil {
		return false
	}

	uid, err := strconv.Atoi(strings.TrimSpace(string(output)))
	if err != nil {
		return false
	}

	return uid == 0
}

// PingHost checks if a host is reachable via ping
func PingHost(ip string, timeout time.Duration) bool {
	cmd := exec.Command("ping", "-c", "1", "-W", fmt.Sprintf("%.0f", timeout.Seconds()), ip)
	err := cmd.Run()
	return err == nil
}

// PortIsOpen checks if a TCP port is open
func PortIsOpen(host string, port int, timeout time.Duration) bool {
	address := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.DialTimeout("tcp", address, timeout)
	if err != nil {
		return false
	}
	defer conn.Close()
	return true
}

// Print utility functions
func PrintBlue(msg string) {
	color.Blue(msg)
}

func PrintCyan(msg string) {
	color.Cyan(msg)
}

func PrintGreen(msg string) {
	color.Green(msg)
}

func PrintYellow(msg string) {
	color.Yellow(msg)
}

func PrintRed(msg string) {
	color.Red(msg)
} 