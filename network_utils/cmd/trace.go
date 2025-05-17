package cmd

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/nicohoff/network_utils/internal/utils"
	"github.com/spf13/cobra"
)

func newTraceCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "trace <hostname/IP>",
		Short: "Trace route to a host",
		Long:  `Trace the network route to a specific host`,
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			runTrace(args[0])
		},
	}

	return cmd
}

func runTrace(target string) {
	utils.PrintBlue("\n=== Traceroute ===")
	utils.PrintCyan(fmt.Sprintf("Target: %s\n", target))
	
	// Check if traceroute is available
	tracerouteCmd := ""
	cmds := []string{"traceroute", "tracert"}
	
	for _, cmd := range cmds {
		if _, err := exec.LookPath(cmd); err == nil {
			tracerouteCmd = cmd
			break
		}
	}
	
	if tracerouteCmd == "" {
		utils.PrintRed("Error: Neither traceroute nor tracert command found on this system")
		return
	}
	
	// Run traceroute
	cmd := exec.Command(tracerouteCmd, target)
	output, err := cmd.CombinedOutput()
	if err != nil {
		// Some error is expected since traceroute can sometimes exit with non-zero
		// when some packets are dropped but the trace is still useful
		utils.PrintYellow(fmt.Sprintf("Warning: %v", err))
	}
	
	// Process and format the output
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if len(line) > 0 {
			fmt.Println(line)
		}
	}
	
	fmt.Println() // Add a newline at the end
} 