package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

func newBluetoothCmd() *cobra.Command {
	bluetoothCmd := &cobra.Command{
		Use:   "bluetooth",
		Short: "Manage Bluetooth audio connections",
		Long:  `Control and manage Bluetooth audio connections and device pairing.`,
	}

	// Add subcommands
	bluetoothCmd.AddCommand(
		newBluetoothListCmd(),
		newBluetoothConnectCmd(),
		newBluetoothDisconnectCmd(),
		newBluetoothScanCmd(),
		newBluetoothPairCmd(),
		newBluetoothSetupCmd(),
	)

	return bluetoothCmd
}

func newBluetoothListCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List paired Bluetooth devices",
		Long:  `List all Bluetooth devices that have been paired with Pixie.`,
		Run: func(cmd *cobra.Command, args []string) {
			color.Blue("=== PAIRED BLUETOOTH DEVICES ===")
			execCmd := exec.Command("bluetoothctl", "paired-devices")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}
}

func newBluetoothConnectCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "connect [device-id]",
		Short: "Connect to a paired Bluetooth device",
		Long:  `Connect to a previously paired Bluetooth device using its MAC address.`,
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			deviceID := args[0]
			fmt.Printf("Connecting to Bluetooth device %s...\n", deviceID)
			execCmd := exec.Command("bluetoothctl", "connect", deviceID)
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			if err := execCmd.Run(); err != nil {
				color.Red("Failed to connect: %v", err)
				os.Exit(1)
			}
			color.Green("Connection successful.")
		},
	}
}

func newBluetoothDisconnectCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "disconnect",
		Short: "Disconnect from connected Bluetooth device",
		Long:  `Disconnect from the currently connected Bluetooth device.`,
		Run: func(cmd *cobra.Command, args []string) {
			// Get connected device
			getDevicesCmd := exec.Command("bluetoothctl", "devices")
			devices, err := getDevicesCmd.Output()
			if err != nil {
				color.Red("Error getting device list: %v", err)
				os.Exit(1)
			}

			var connectedDevice string
			deviceLines := strings.Split(string(devices), "\n")
			
			for _, line := range deviceLines {
				if line == "" {
					continue
				}
				
				parts := strings.Split(line, " ")
				if len(parts) < 2 {
					continue
				}
				
				deviceID := parts[1]
				infoCmd := exec.Command("bluetoothctl", "info", deviceID)
				info, err := infoCmd.Output()
				if err != nil {
					continue
				}
				
				if strings.Contains(string(info), "Connected: yes") {
					connectedDevice = deviceID
					break
				}
			}
			
			if connectedDevice == "" {
				color.Yellow("No connected Bluetooth device found.")
				return
			}
			
			fmt.Printf("Disconnecting from Bluetooth device %s...\n", connectedDevice)
			execCmd := exec.Command("bluetoothctl", "disconnect", connectedDevice)
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			if err := execCmd.Run(); err != nil {
				color.Red("Failed to disconnect: %v", err)
				os.Exit(1)
			}
			color.Green("Successfully disconnected.")
		},
	}
}

func newBluetoothScanCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "scan",
		Short: "Scan for Bluetooth devices",
		Long:  `Scan for available Bluetooth devices for 10 seconds.`,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Scanning for Bluetooth devices for 10 seconds...")
			fmt.Println("Press Ctrl+C to stop scanning early.")
			
			// Start scanning in background
			scanCmd := exec.Command("bluetoothctl", "scan", "on")
			if err := scanCmd.Start(); err != nil {
				color.Red("Failed to start scanning: %v", err)
				os.Exit(1)
			}
			
			// Wait for scan duration
			time.Sleep(10 * time.Second)
			
			// Stop scanning
			scanCmd.Process.Kill()
			exec.Command("bluetoothctl", "scan", "off").Run()
			
			fmt.Println("Scan complete. Found devices:")
			listCmd := exec.Command("bluetoothctl", "devices")
			listCmd.Stdout = os.Stdout
			listCmd.Stderr = os.Stderr
			listCmd.Run()
		},
	}
	return cmd
}

func newBluetoothPairCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "pair [device-id]",
		Short: "Pair with a Bluetooth device",
		Long:  `Pair with a found Bluetooth device using its MAC address.`,
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			deviceID := args[0]
			fmt.Printf("Pairing with Bluetooth device %s...\n", deviceID)
			
			pairCmd := exec.Command("bluetoothctl", "pair", deviceID)
			pairCmd.Stdout = os.Stdout
			pairCmd.Stderr = os.Stderr
			pairCmd.Run()
			
			fmt.Println("Attempting to connect...")
			connectCmd := exec.Command("bluetoothctl", "connect", deviceID)
			connectCmd.Stdout = os.Stdout
			connectCmd.Stderr = os.Stderr
			connectCmd.Run()
		},
	}
}

func newBluetoothSetupCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "setup",
		Short: "Configure Bluetooth for Pixie",
		Long:  `Configure the Bluetooth adapter for Pixie audio use (discoverable, pairable, sets device class to audio sink).`,
		Run: func(cmd *cobra.Command, args []string) {
			color.Blue("Configuring Bluetooth for Pixie...")
			
			fmt.Println("Setting Bluetooth to be discoverable and pairable...")
			exec.Command("sudo", "bluetoothctl", "power", "on").Run()
			exec.Command("sudo", "bluetoothctl", "discoverable", "on").Run()
			exec.Command("sudo", "bluetoothctl", "pairable", "on").Run()
			exec.Command("sudo", "bluetoothctl", "agent", "NoInputNoOutput").Run()
			exec.Command("sudo", "bluetoothctl", "default-agent").Run()
			
			fmt.Println("Setting device class to audio sink...")
			exec.Command("sudo", "hciconfig", "hci0", "class", "0x240414").Run()
			
			fmt.Println("Setting device name to Pixie...")
			exec.Command("sudo", "hciconfig", "hci0", "name", "Pixie").Run()
			
			fmt.Println("Restarting Bluetooth service...")
			exec.Command("sudo", "systemctl", "restart", "bluetooth").Run()
			exec.Command("sudo", "systemctl", "restart", "bluetooth-boot.service").Run()
			exec.Command("sudo", "systemctl", "restart", "a2dp-agent.service").Run()
			exec.Command("sudo", "systemctl", "restart", "simple-agent.service").Run()
			
			color.Green("Bluetooth configuration complete.")
			fmt.Println("Pixie should now be visible as a Bluetooth speaker and allow pairing without PIN.")
			fmt.Println("You can pair and connect from your devices now.")
		},
	}
} 