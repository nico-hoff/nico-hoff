package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

func newControlCmd() *cobra.Command {
	controlCmd := &cobra.Command{
		Use:   "control",
		Short: "Control audio services",
		Long:  `Control and manage audio services like Spotify, AirPlay, and service restart.`,
	}

	// Add subcommands
	controlCmd.AddCommand(
		newControlRestartCmd(),
		newControlStatusCmd(),
		newControlSpotifyVolumeCmd(),
		newControlAirplayVolumeCmd(),
	)

	return controlCmd
}

func newControlRestartCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "restart",
		Short: "Restart audio services",
		Long:  `Restart the Shairport Sync (AirPlay) and Librespot (Spotify) services.`,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Restarting audio services...")
			execCmd := exec.Command("sudo", "systemctl", "restart", "shairport-sync.service")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()

			execCmd = exec.Command("sudo", "systemctl", "restart", "librespot.service")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()

			color.Green("Audio services restarted successfully.")
		},
	}
}

func newControlStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Show status of audio services",
		Long:  `Display the current status of all audio services.`,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("=== SERVICES STATUS ===")
			execCmd := exec.Command("sudo", "systemctl", "status", "shairport-sync.service", "--no-pager")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()

			execCmd = exec.Command("sudo", "systemctl", "status", "librespot.service", "--no-pager")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()

			execCmd = exec.Command("sudo", "systemctl", "status", "bluetooth.service", "--no-pager")
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr
			execCmd.Run()
		},
	}
}

func newControlSpotifyVolumeCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "spotify-volume [0-100]",
		Short: "Set Spotify volume",
		Long:  `Set the volume level for the Spotify Connect stream (0-100).`,
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			volume, err := strconv.Atoi(args[0])
			if err != nil || volume < 0 || volume > 100 {
				color.Red("Error: Volume must be a number between 0 and 100.")
				os.Exit(1)
			}

			// Get sink ID for librespot
			getSinkCmd := exec.Command("sudo", "-u", "pulse", "pactl", "list", "sink-inputs", "short")
			sinkOutput, err := getSinkCmd.Output()
			if err != nil {
				color.Red("Error getting sink information: %v", err)
				os.Exit(1)
			}

			// Parse output to find librespot sink
			findLibrespotCmd := exec.Command("bash", "-c", fmt.Sprintf("echo '%s' | grep librespot | awk '{print $1}'", string(sinkOutput)))
			sinkID, err := findLibrespotCmd.Output()
			if err != nil || len(sinkID) == 0 {
				color.Yellow("No Spotify stream found")
				return
			}

			// Set volume
			volumeCmd := exec.Command("sudo", "-u", "pulse", "pactl", "set-sink-input-volume", string(sinkID[:len(sinkID)-1]), fmt.Sprintf("%d%%", volume))
			err = volumeCmd.Run()
			if err != nil {
				color.Red("Error setting volume: %v", err)
				os.Exit(1)
			}

			color.Green("Spotify volume set to %d%%", volume)
		},
	}
}

func newControlAirplayVolumeCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "airplay-volume [0-100]",
		Short: "Set AirPlay volume",
		Long:  `Set the volume level for the AirPlay (Shairport Sync) stream (0-100).`,
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			volume, err := strconv.Atoi(args[0])
			if err != nil || volume < 0 || volume > 100 {
				color.Red("Error: Volume must be a number between 0 and 100.")
				os.Exit(1)
			}

			// Get sink ID for shairport
			getSinkCmd := exec.Command("sudo", "-u", "pulse", "pactl", "list", "sink-inputs", "short")
			sinkOutput, err := getSinkCmd.Output()
			if err != nil {
				color.Red("Error getting sink information: %v", err)
				os.Exit(1)
			}

			// Parse output to find shairport sink
			findShairportCmd := exec.Command("bash", "-c", fmt.Sprintf("echo '%s' | grep shairport | awk '{print $1}'", string(sinkOutput)))
			sinkID, err := findShairportCmd.Output()
			if err != nil || len(sinkID) == 0 {
				color.Yellow("No AirPlay stream found")
				return
			}

			// Set volume
			volumeCmd := exec.Command("sudo", "-u", "pulse", "pactl", "set-sink-input-volume", string(sinkID[:len(sinkID)-1]), fmt.Sprintf("%d%%", volume))
			err = volumeCmd.Run()
			if err != nil {
				color.Red("Error setting volume: %v", err)
				os.Exit(1)
			}

			color.Green("AirPlay volume set to %d%%", volume)
		},
	}
} 