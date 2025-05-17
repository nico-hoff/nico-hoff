package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/nicohoff/network_utils/internal/utils"
	"github.com/spf13/cobra"
)

func newSniffCmd() *cobra.Command {
	var iface string
	var packetCount int
	var duration int
	var filter string
	var outFile string

	cmd := &cobra.Command{
		Use:   "sniff",
		Short: "Capture and analyze network traffic",
		Long:  `Capture and analyze network traffic using tcpdump`,
		Run: func(cmd *cobra.Command, args []string) {
			runSniff(iface, packetCount, duration, filter, outFile)
		},
	}

	cmd.Flags().StringVarP(&iface, "interface", "i", "", "Network interface to capture on")
	cmd.Flags().IntVarP(&packetCount, "packets", "p", 100, "Number of packets to capture")
	cmd.Flags().IntVarP(&duration, "duration", "d", 0, "Duration to capture in seconds")
	cmd.Flags().StringVarP(&filter, "filter", "f", "", "Filter expression (tcpdump syntax)")
	cmd.Flags().StringVarP(&outFile, "output", "o", "", "Output file for packet capture")

	return cmd
}

func runSniff(iface string, packetCount, duration int, filter, outFile string) {
	// Check if tcpdump is installed
	if _, err := exec.LookPath("tcpdump"); err != nil {
		utils.PrintRed("Error: tcpdump is not installed. Please install it to use this feature.")
		return
	}

	// Check for root privileges
	if !utils.IsRoot() {
		utils.PrintYellow("Warning: Running without root privileges. Some capture features may be limited.")
	}

	// If no interface specified, use the default one
	if iface == "" {
		netInfo, err := utils.GetNetworkInfo()
		if err != nil {
			utils.PrintRed(fmt.Sprintf("Error: %v", err))
			return
		}
		iface = netInfo.Interface
	}

	utils.PrintBlue("\n=== Network Sniffer ===")
	utils.PrintCyan(fmt.Sprintf("Interface: %s", iface))
	utils.PrintCyan(fmt.Sprintf("Packet count: %d", packetCount))
	if duration > 0 {
		utils.PrintCyan(fmt.Sprintf("Duration: %d seconds", duration))
	}
	if filter != "" {
		utils.PrintCyan(fmt.Sprintf("Filter: %s", filter))
	}
	if outFile != "" {
		utils.PrintCyan(fmt.Sprintf("Output file: %s", outFile))
	}
	fmt.Println()

	// Build tcpdump command
	args := []string{"-i", iface, "-c", fmt.Sprintf("%d", packetCount), "-nn"}

	if outFile != "" {
		args = append(args, "-w", outFile)
	}

	if filter != "" {
		args = append(args, filter)
	}

	// Run tcpdump with duration limit if specified
	if duration > 0 {
		if outFile != "" {
			utils.PrintGreen(fmt.Sprintf("Capturing packets to file %s for %d seconds...", outFile, duration))

			// Run tcpdump in background
			cmd := exec.Command("tcpdump", args...)
			err := cmd.Start()
			if err != nil {
				utils.PrintRed(fmt.Sprintf("Error starting tcpdump: %v", err))
				return
			}

			// Set up timeout
			time.Sleep(time.Duration(duration) * time.Second)

			// Gracefully terminate the process
			cmd.Process.Signal(syscall.SIGTERM)
			cmd.Wait()

			utils.PrintGreen(fmt.Sprintf("Capture complete. File saved to: %s", outFile))

			// Show summary of captured packets if file exists
			if _, err := os.Stat(outFile); err == nil {
				utils.PrintCyan("\nPacket summary (first 20 packets):")
				summaryCmd := exec.Command("tcpdump", "-r", outFile, "-nn")
				output, _ := summaryCmd.CombinedOutput()
				lines := strings.Split(string(output), "\n")
				for i, line := range lines {
					if i >= 20 {
						break
					}
					if len(line) > 0 {
						fmt.Println(line)
					}
				}
			}
		} else {
			utils.PrintGreen(fmt.Sprintf("Capturing packets for %d seconds...", duration))

			// Create a command
			cmd := exec.Command("tcpdump", args...)

			// Set up pipes for stdout
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr

			// Start the command
			if err := cmd.Start(); err != nil {
				utils.PrintRed(fmt.Sprintf("Error: %v", err))
				return
			}

			// Set up signal handling for graceful termination
			sigChan := make(chan os.Signal, 1)
			signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

			// Wait for duration or signal
			select {
			case <-time.After(time.Duration(duration) * time.Second):
				// Time's up, terminate the process
				cmd.Process.Signal(syscall.SIGTERM)
			case <-sigChan:
				// Received interrupt, terminate the process
				cmd.Process.Signal(syscall.SIGTERM)
				utils.PrintYellow("\nCapture interrupted by user")
			}

			// Wait for the process to exit
			cmd.Wait()
		}
	} else {
		// Run tcpdump directly without duration limit
		utils.PrintGreen("Starting packet capture...")

		cmd := exec.Command("tcpdump", args...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		// Run the command
		if err := cmd.Run(); err != nil {
			utils.PrintRed(fmt.Sprintf("Error: %v", err))
		}
	}
}
