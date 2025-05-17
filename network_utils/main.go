package main

import (
	"fmt"
	"os"

	"github.com/nicohoff/network_utils/cmd"
	"github.com/spf13/cobra"
)

func main() {
	var rootCmd = &cobra.Command{
		Use:   "network_utils",
		Short: "A comprehensive network utility tool",
		Long: `A comprehensive network utility tool that combines port scanning, 
network discovery, packet sniffing, and other common network operations.`,
	}

	// Add commands
	cmd.AddCommands(rootCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
} 