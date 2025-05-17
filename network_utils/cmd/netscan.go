package cmd

import (
	"fmt"
	"os"
	"sync"
	"text/tabwriter"
	"time"

	"github.com/nicohoff/network_utils/internal/utils"
	"github.com/spf13/cobra"
	"golang.org/x/sync/errgroup"
)

type HostScanResult struct {
	IP        string
	Hostname  string
	OpenPorts []PortResult
}

func newNetscanCmd() *cobra.Command {
	var concurrency int
	var pingTimeout int
	var portTimeout int
	var showAll bool

	cmd := &cobra.Command{
		Use:   "netscan",
		Short: "Scan well-known ports on all reachable hosts in the local network",
		Long:  `Scan well-known ports (1-1024) on all reachable hosts in the local network`,
		Run: func(cmd *cobra.Command, args []string) {
			runNetscan(concurrency, pingTimeout, portTimeout, showAll)
		},
	}

	cmd.Flags().IntVarP(&concurrency, "concurrency", "c", 50, "Number of hosts to scan in parallel")
	cmd.Flags().IntVarP(&pingTimeout, "timeout", "t", 1, "Host discovery timeout in seconds")
	cmd.Flags().IntVarP(&portTimeout, "port-timeout", "p", 1, "Port scan timeout in seconds")
	cmd.Flags().BoolVarP(&showAll, "all", "a", false, "Show all hosts, even those without hostname")

	return cmd
}

func runNetscan(concurrency, pingTimeout, portTimeout int, showAll bool) {
	utils.PrintBlue("\n=== Network-wide Port Scanner ===")
	utils.PrintCyan("Scanning all reachable hosts for well-known ports (1-1024)")
	utils.PrintCyan(fmt.Sprintf("Concurrency: %d (hosts scanned in parallel)", concurrency))
	utils.PrintCyan(fmt.Sprintf("Port timeout: %d seconds", portTimeout))

	// Phase 1: Discover active hosts
	utils.PrintGreen("\nPhase 1: Discovering active hosts on the network...")

	netInfo, err := utils.GetNetworkInfo()
	if err != nil {
		utils.PrintRed(fmt.Sprintf("Error: %v", err))
		return
	}

	// Channel to collect active hosts
	activeHosts := make(chan string, netInfo.NumHosts)

	// Scan the network with a worker pool
	var wg sync.WaitGroup
	hostWorkerLimit := make(chan struct{}, 50) // Limit concurrent host discovery

	for i := 1; i < netInfo.NumHosts-1; i++ {
		ip := fmt.Sprintf("%s.%d", netInfo.NetworkPrefix, i)
		wg.Add(1)

		go func(ip string) {
			defer wg.Done()
			hostWorkerLimit <- struct{}{}        // Acquire a slot
			defer func() { <-hostWorkerLimit }() // Release when done

			// Check if host is reachable
			if utils.PingHost(ip, time.Duration(pingTimeout)*time.Second) {
				// Only include hosts with known hostnames or if showAll is true
				name := getHostname(ip)
				if showAll || name != "unknown" {
					activeHosts <- ip
				}
			}
		}(ip)
	}

	// Close the channel once all workers are done
	go func() {
		wg.Wait()
		close(activeHosts)
	}()

	// Collect all active hosts into a slice
	var hosts []string
	for host := range activeHosts {
		hosts = append(hosts, host)
	}

	hostCount := len(hosts)
	utils.PrintGreen(fmt.Sprintf("Found %d active hosts", hostCount))

	// Exit if no hosts found
	if hostCount == 0 {
		utils.PrintRed("No active hosts found. Exiting.")
		return
	}

	// Phase 2: Scan ports on each host
	utils.PrintGreen("\nPhase 2: Scanning each host for well-known ports (1-1024)...")
	utils.PrintYellow("This may take some time depending on the number of hosts.")

	// Channel for scan results
	results := make(chan HostScanResult, hostCount)

	// Create a pool of workers to scan hosts
	var eg errgroup.Group
	hostChan := make(chan string, hostCount)

	// Start the worker goroutines
	for i := 0; i < concurrency; i++ {
		eg.Go(func() error {
			for host := range hostChan {
				// Scan all well-known ports (1-1024) on this host
				openPorts := scanHostPorts(host, 1, 1024, portTimeout)

				if len(openPorts) > 0 {
					// Get hostname
					hostname := getHostname(host)

					results <- HostScanResult{
						IP:        host,
						Hostname:  hostname,
						OpenPorts: openPorts,
					}
				}
			}
			return nil
		})
	}

	// Queue hosts for scanning
	for i, host := range hosts {
		hostChan <- host

		// Print progress
		fmt.Printf("\rProgress: %d%% (%d/%d hosts)", (i+1)*100/hostCount, i+1, hostCount)
	}

	// Close the channel to signal no more hosts
	close(hostChan)

	// Wait for all workers to finish
	go func() {
		eg.Wait()
		close(results)
	}()

	// Collect and display results
	var scanResults []HostScanResult
	for result := range results {
		scanResults = append(scanResults, result)
	}

	// Print results
	fmt.Println() // Clear the progress line
	utils.PrintGreen("\nScan complete. Results:")
	utils.PrintYellow("\n=== Network-wide Port Scan Results ===")

	// Use tabwriter for nicely formatted output
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)

	for _, hostResult := range scanResults {
		fmt.Fprintf(w, "\n=== Host: %s (%s) ===\n\n", hostResult.IP, hostResult.Hostname)
		fmt.Fprintf(w, "Port\tService\tBanner\n")
		fmt.Fprintf(w, "----\t-------\t------\n")

		for _, port := range hostResult.OpenPorts {
			fmt.Fprintf(w, "%d\t%s\t%s\n", port.Port, port.Service, port.Banner)
		}
	}

	w.Flush()
	fmt.Println() // Add a newline at the end
}

// scanHostPorts scans a range of ports on a host and returns open ports
func scanHostPorts(host string, startPort, endPort, timeout int) []PortResult {
	var results []PortResult
	timeoutDuration := time.Duration(timeout) * time.Second

	// Use a worker pool to scan ports in parallel
	const portConcurrency = 200 // Scan 200 ports at a time
	var wg sync.WaitGroup
	portChan := make(chan int, endPort-startPort+1)
	resultChan := make(chan PortResult)

	// Start workers
	for i := 0; i < portConcurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for port := range portChan {
				if utils.PortIsOpen(host, port, timeoutDuration) {
					service := utils.ServiceNames[port]
					if service == "" {
						service = "unknown"
					}

					banner := getBanner(host, port, timeoutDuration)

					resultChan <- PortResult{
						Port:    port,
						Service: service,
						Banner:  banner,
					}
				}
			}
		}()
	}

	// Close result channel when all workers are done
	go func() {
		wg.Wait()
		close(resultChan)
	}()

	// Queue all ports
	for port := startPort; port <= endPort; port++ {
		portChan <- port
	}
	close(portChan)

	// Collect results
	for result := range resultChan {
		results = append(results, result)
	}

	return results
}
