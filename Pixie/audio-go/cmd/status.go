package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

func newStatusCmd() *cobra.Command {
	statusCmd := &cobra.Command{
		Use:   "status",
		Short: "Show status of the audio system",
		Long:  `Display the current status of all audio components and streams.`,
		Run:   runStatusCmd,
	}
	return statusCmd
}

func runStatusCmd(cmd *cobra.Command, args []string) {
	// Print header
	color.Blue("==== PULSEAUDIO SINKS ====")
	// List PulseAudio sinks
	sinkCmd := exec.Command("sudo", "-u", "pulse", "pactl", "list", "sinks", "short")
	sinkCmd.Stdout = os.Stdout
	sinkCmd.Stderr = os.Stderr
	sinkCmd.Run()

	// Print streams header
	fmt.Println("")
	color.Blue("==== AUDIO STREAMS ====")
	// List PulseAudio streams
	streamCmd := exec.Command("sudo", "-u", "pulse", "pactl", "list", "sink-inputs", "short")
	streamCmd.Stdout = os.Stdout
	streamCmd.Stderr = os.Stderr
	streamCmd.Run()

	// Print ALSA header
	fmt.Println("")
	color.Blue("==== ALSA MIXER ====")
	// Get ALSA mixer status
	mixerCmd := exec.Command("amixer", "-c", "0", "get", "PCM")
	mixerCmd.Stdout = os.Stdout
	mixerCmd.Stderr = os.Stderr
	mixerCmd.Run()

	// Show service statuses
	fmt.Println("")
	color.Blue("==== SERVICES STATUS ====")
	
	// Shairport status
	color.Cyan("• Shairport Sync (AirPlay):")
	shairportCmd := exec.Command("systemctl", "is-active", "shairport-sync.service")
	shairportOutput, err := shairportCmd.Output()
	if err == nil && string(shairportOutput) == "active\n" {
		color.Green("  Running")
	} else {
		color.Red("  Not running")
	}

	// Librespot status
	color.Cyan("• Librespot (Spotify):")
	librespotCmd := exec.Command("systemctl", "is-active", "librespot.service")
	librespotOutput, err := librespotCmd.Output()
	if err == nil && string(librespotOutput) == "active\n" {
		color.Green("  Running")
	} else {
		color.Red("  Not running")
	}

	// Bluetooth status
	color.Cyan("• Bluetooth:")
	bluetoothCmd := exec.Command("systemctl", "is-active", "bluetooth.service")
	bluetoothOutput, err := bluetoothCmd.Output()
	if err == nil && string(bluetoothOutput) == "active\n" {
		color.Green("  Running")
	} else {
		color.Red("  Not running")
	}

	// Master volume timer
	color.Cyan("• Volume Control:")
	volumeCmd := exec.Command("systemctl", "is-active", "ensure-master-volume.timer")
	volumeOutput, err := volumeCmd.Output()
	if err == nil && string(volumeOutput) == "active\n" {
		color.Green("  Running")
	} else {
		color.Red("  Not running")
	}

	// Connected Bluetooth devices
	fmt.Println("")
	color.Blue("==== CONNECTED BLUETOOTH DEVICES ====")
	
	// List connected Bluetooth devices
	connectedCmd := exec.Command("bash", "-c", `bluetoothctl devices | while read -r line; do
		device_id=$(echo "$line" | awk '{print $2}')
		is_connected=$(bluetoothctl info "$device_id" | grep "Connected:" | awk '{print $2}')
		
		if [ "$is_connected" = "yes" ]; then
			echo "$line (Connected)"
		fi
	done`)
	connectedCmd.Stdout = os.Stdout
	connectedCmd.Stderr = os.Stderr
	connectedCmd.Run()
} 