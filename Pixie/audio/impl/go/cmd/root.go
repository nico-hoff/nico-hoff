package cmd

import (
	"github.com/spf13/cobra"
)

func NewRootCmd() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:   "pixie-audio",
		Short: "Pixie Audio System - Golang Implementation",
		Long: `Pixie Audio System provides an interface to control audio services on your Pixie device.
This includes AirPlay (Shairport Sync), Spotify Connect (Librespot), and Bluetooth audio capabilities.`,
	}

	// Add subcommands
	rootCmd.AddCommand(
		newSetupCmd(),
		newStatusCmd(),
		newControlCmd(),
		newHealthCmd(),
		newBluetoothCmd(),
		newVolumeCmd(),
	)

	return rootCmd
} 