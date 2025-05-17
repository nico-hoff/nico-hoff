package cmd

import (
	"fmt"
	"net"
	"os/exec"
	"strings"

	"github.com/nicohoff/network_utils/internal/utils"
	"github.com/spf13/cobra"
)

func newInfoCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "info",
		Short: "Display network interface information",
		Long:  `Display detailed information about network interfaces`,
		Run: func(cmd *cobra.Command, args []string) {
			runInfo()
		},
	}

	return cmd
}

func runInfo() {
	netInfo, err := utils.GetNetworkInfo()
	if err != nil {
		utils.PrintRed(fmt.Sprintf("Error: %v", err))
		return
	}

	utils.PrintBlue("\n=== Network Interface Information ===")
	utils.PrintCyan(fmt.Sprintf("Interface: %s", netInfo.Interface))
	utils.PrintCyan(fmt.Sprintf("IP Address: %s", netInfo.LocalIP))
	utils.PrintCyan(fmt.Sprintf("Default Gateway: %s", netInfo.Gateway))
	utils.PrintCyan(fmt.Sprintf("Network: %s.0/%d", netInfo.NetworkPrefix, netInfo.CIDR))
	utils.PrintCyan(fmt.Sprintf("Broadcast: %s", netInfo.Broadcast))
	utils.PrintCyan(fmt.Sprintf("Netmask: %s", netInfo.Netmask))

	// Display active interfaces
	utils.PrintBlue("\n=== Active Interfaces ===")

	ifaces, err := net.Interfaces()
	if err != nil {
		utils.PrintRed(fmt.Sprintf("Error listing interfaces: %v", err))
		return
	}

	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp != 0 {
			// Check if the interface has an IPv4 address
			addrs, err := iface.Addrs()
			if err != nil {
				continue
			}

			hasIPv4 := false
			for _, addr := range addrs {
				if ipnet, ok := addr.(*net.IPNet); ok && ipnet.IP.To4() != nil {
					hasIPv4 = true
					break
				}
			}

			status := "active"
			if iface.Flags&net.FlagLoopback != 0 {
				status = "loopback"
			} else if !hasIPv4 {
				status = "no IPv4"
			}

			if iface.Flags&net.FlagUp != 0 {
				utils.PrintGreen(fmt.Sprintf("%s (%s)", iface.Name, status))
			} else {
				utils.PrintYellow(fmt.Sprintf("%s (inactive)", iface.Name))
			}
		}
	}

	// Display connection statistics if netstat is available
	utils.PrintBlue("\n=== Connection Statistics ===")

	// Try to get statistics using netstat
	cmd := exec.Command("netstat", "-i")
	output, err := cmd.Output()
	if err == nil {
		lines := strings.Split(string(output), "\n")
		if len(lines) > 0 {
			// Print header
			fmt.Println(lines[0])

			// Find and print our interface's statistics
			for _, line := range lines[1:] {
				if strings.HasPrefix(line, netInfo.Interface) {
					fmt.Println(line)
					break
				}
			}
		}
	} else {
		// Fallback to simple interface statistics if netstat not available
		iface, err := net.InterfaceByName(netInfo.Interface)
		if err == nil {
			fmt.Printf("Interface: %s, MTU: %d, Hardware: %s\n",
				iface.Name, iface.MTU, iface.HardwareAddr)
		} else {
			utils.PrintYellow("Could not get detailed statistics (netstat not available)")
		}
	}

	// DNS servers
	utils.PrintBlue("\n=== DNS Configuration ===")

	// Read /etc/resolv.conf to get DNS servers
	cmd = exec.Command("cat", "/etc/resolv.conf")
	output, err = cmd.Output()
	if err == nil {
		dnsServers := []string{}
		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.HasPrefix(line, "nameserver") {
				parts := strings.Fields(line)
				if len(parts) >= 2 {
					dnsServers = append(dnsServers, parts[1])
				}
			}
		}

		if len(dnsServers) > 0 {
			for i, server := range dnsServers {
				fmt.Printf("DNS Server %d: %s\n", i+1, server)
			}
		} else {
			utils.PrintYellow("No DNS servers found in /etc/resolv.conf")
		}
	} else {
		utils.PrintYellow("Could not read DNS configuration")
	}

	fmt.Println() // Add a newline at the end
}
