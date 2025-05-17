package cmd

import (
	"github.com/spf13/cobra"
)

// AddCommands adds all network utility commands to the root command
func AddCommands(rootCmd *cobra.Command) {
	rootCmd.AddCommand(newScanCmd())
	rootCmd.AddCommand(newPortscanCmd())
	rootCmd.AddCommand(newNetscanCmd())
	rootCmd.AddCommand(newSniffCmd())
	rootCmd.AddCommand(newLookupCmd())
	rootCmd.AddCommand(newTraceCmd())
	rootCmd.AddCommand(newMonitorCmd())
	rootCmd.AddCommand(newInfoCmd())
	rootCmd.AddCommand(newSpeedCmd())
} 