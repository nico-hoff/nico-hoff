package cmd

import (
	"fmt"
	"net"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/fatih/color"
	"github.com/nicohoff/network_utils/internal/utils"
	"github.com/spf13/cobra"
)

type PortResult struct {
	Port    int
	Service string
	Banner  string
}

func newPortscanCmd() *cobra.Command {
	var concurrency int
	var timeout int

	cmd := &cobra.Command{
		Use:   "portscan [target] [range]",
		Short: "Scan a specific host for open ports",
		Long: `Scan a specific host for open ports.
Port ranges: 0=Well-known(1-1024), 1=Registered(1025-49151), 2=Private(49152-65535), 3=All`,
		Args: cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			target := args[0]

			// Default range is well-known ports (0)
			rangeVal := 0
			if len(args) > 1 {
				val, err := strconv.Atoi(args[1])
				if err == nil && val >= 0 && val <= 3 {
					rangeVal = val
				}
			}

			runPortscan(target, rangeVal, concurrency, timeout)
		},
	}

	cmd.Flags().IntVarP(&concurrency, "concurrency", "c", 200, "Number of concurrent port scans")
	cmd.Flags().IntVarP(&timeout, "timeout", "t", 1, "Connection timeout in seconds")

	return cmd
}

func runPortscan(target string, rangeVal, concurrency, timeout int) {
	// Determine port range
	var portStart, portEnd int
	var rangeName string

	switch rangeVal {
	case 0:
		portStart, portEnd = 1, 1024
		rangeName = "Well-known ports"
	case 1:
		portStart, portEnd = 1025, 49151
		rangeName = "Registered ports"
	case 2:
		portStart, portEnd = 49152, 65535
		rangeName = "Private ports"
	case 3:
		portStart, portEnd = 1, 65535
		rangeName = "All ports"
	default:
		portStart, portEnd = 1, 1024
		rangeName = "Well-known ports"
	}

	totalPorts := portEnd - portStart + 1

	// If target is a hostname, try to resolve it
	ipTarget := target
	if !isIPAddress(target) {
		utils.PrintCyan(fmt.Sprintf("Resolving hostname %s...", target))
		ips, err := net.LookupHost(target)
		if err != nil || len(ips) == 0 {
			utils.PrintRed(fmt.Sprintf("Error: Could not resolve hostname '%s'", target))
			return
		}

		utils.PrintCyan(fmt.Sprintf("Resolved to IP: %s", ips[0]))
		ipTarget = ips[0]
	}

	// Try to get hostname
	hostname := target
	if isIPAddress(target) {
		names, err := net.LookupAddr(target)
		if err == nil && len(names) > 0 {
			hostname = strings.TrimSuffix(names[0], ".")
		}
	}

	utils.PrintBlue("\n=== Port Scanner ===")
	utils.PrintCyan(fmt.Sprintf("Target: %s", target))
	if target != ipTarget {
		utils.PrintCyan(fmt.Sprintf("IP Address: %s", ipTarget))
	}
	utils.PrintCyan(fmt.Sprintf("Hostname: %s", hostname))
	utils.PrintCyan(fmt.Sprintf("Scanning: %s (%d-%d)", rangeName, portStart, portEnd))
	utils.PrintCyan(fmt.Sprintf("Total ports to scan: %d", totalPorts))
	utils.PrintCyan(fmt.Sprintf("Concurrency: %d\n", concurrency))

	// Print header
	fmt.Printf("%-8s %-20s %-30s\n", "Port", "Service", "Banner")
	fmt.Printf("%-8s %-20s %-30s\n", "--------", "--------------------", "------------------------------")

	// Channel for results
	results := make(chan PortResult)

	// Start a goroutine to collect and sort results
	var wg sync.WaitGroup
	go func() {
		var portResults []PortResult
		for result := range results {
			portResults = append(portResults, result)
		}

		// Sort results by port
		sort.Slice(portResults, func(i, j int) bool {
			return portResults[i].Port < portResults[j].Port
		})

		// Print results
		green := color.New(color.FgGreen).SprintfFunc()
		for _, result := range portResults {
			fmt.Printf(green("%-8d %-20s %-30s\n", result.Port, result.Service, result.Banner))
		}

		if len(portResults) == 0 {
			utils.PrintYellow("No open ports found.")
		}
	}()

	// Process ports in batches using worker pool
	portChan := make(chan int, totalPorts)
	timeoutDuration := time.Duration(timeout) * time.Second

	// Launch worker goroutines
	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()

			for port := range portChan {
				if utils.PortIsOpen(ipTarget, port, timeoutDuration) {
					service := utils.ServiceNames[port]
					if service == "" {
						service = "unknown"
					}

					banner := getBanner(ipTarget, port, timeoutDuration)

					results <- PortResult{
						Port:    port,
						Service: service,
						Banner:  banner,
					}
				}
			}
		}()
	}

	// Queue all ports for scanning
	for port := portStart; port <= portEnd; port++ {
		portChan <- port

		// Print progress every 5000 ports
		if port%5000 == 0 {
			percentDone := float64(port-portStart) / float64(totalPorts) * 100
			fmt.Printf("\rProgress: %.1f%% (%d/%d ports)", percentDone, port-portStart, totalPorts)
		}
	}

	// Close the channel to signal no more ports
	close(portChan)

	// Wait for all workers to finish
	wg.Wait()
	close(results)

	fmt.Println() // Add a newline at the end
}

// isIPAddress checks if a string is a valid IP address
func isIPAddress(s string) bool {
	return net.ParseIP(s) != nil
}

// getBanner attempts to get a service banner
func getBanner(host string, port int, timeout time.Duration) string {
	var banner string

	// Try to get banner for common services
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", host, port), timeout)
	if err != nil {
		return ""
	}
	defer conn.Close()

	// Set a deadline for reading
	conn.SetReadDeadline(time.Now().Add(timeout))

	// For HTTP-like services, send a request
	if port == 80 || port == 443 || port == 8080 || port == 8443 {
		_, err = conn.Write([]byte("HEAD / HTTP/1.0\r\n\r\n"))
		if err != nil {
			return ""
		}
	}

	// Read response
	buf := make([]byte, 1024)
	n, err := conn.Read(buf)
	if err != nil {
		return ""
	}

	banner = string(buf[:n])

	// Extract first line
	if idx := strings.Index(banner, "\n"); idx > 0 {
		banner = banner[:idx]
	}

	// Truncate if too long
	if len(banner) > 28 {
		banner = banner[:25] + "..."
	}

	return banner
}
