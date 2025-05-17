package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

func newVolumeCmd() *cobra.Command {
	volumeCmd := &cobra.Command{
		Use:   "volume",
		Short: "Control system volume",
		Long:  `Control the main system volume and ensure volume levels.`,
	}

	// Add subcommands
	volumeCmd.AddCommand(
		newVolumeEnsureCmd(),
		newVolumeSetCmd(),
		newVolumeGetCmd(),
	)

	return volumeCmd
}

func newVolumeEnsureCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "ensure",
		Short: "Ensure master volume is set to 100%",
		Long:  `Set ALSA and PulseAudio master volumes to 100% (equivalent to ensure-master-volume.sh).`,
		Run: func(cmd *cobra.Command, args []string) {
			// Set ALSA master to 100%
			alsaCmd := exec.Command("amixer", "-c", "0", "set", "PCM", "100%")
			if err := alsaCmd.Run(); err != nil {
				color.Red("Error setting ALSA volume: %v", err)
			}

			// Set PulseAudio master sink to 100%
			pulseCmd := exec.Command("sudo", "-u", "pulse", "pactl", "set-sink-volume", "@DEFAULT_SINK@", "100%")
			if err := pulseCmd.Run(); err != nil {
				color.Red("Error setting PulseAudio volume: %v", err)
			}

			color.Green("Master volume set to 100%")
		},
	}
}

func newVolumeSetCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "set [0-100]",
		Short: "Set master volume",
		Long:  `Set the master volume to a specific level (0-100).`,
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			volume := args[0]
			// Validate volume as percent
			if len(volume) == 0 || volume[len(volume)-1] != '%' {
				volume = volume + "%"
			}

			// Set PulseAudio master sink volume
			pulseCmd := exec.Command("sudo", "-u", "pulse", "pactl", "set-sink-volume", "@DEFAULT_SINK@", volume)
			pulseCmd.Stderr = os.Stderr
			if err := pulseCmd.Run(); err != nil {
				color.Red("Error setting PulseAudio volume: %v", err)
				os.Exit(1)
			}

			color.Green("Master volume set to %s", volume)
		},
	}
	return cmd
}

func newVolumeGetCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "get",
		Short: "Get current master volume",
		Long:  `Display the current master volume level.`,
		Run: func(cmd *cobra.Command, args []string) {
			// Get current PulseAudio volume
			fmt.Println("Current volume levels:")

			// Get PulseAudio default sink volume
			pulseCmd := exec.Command("bash", "-c", "sudo -u pulse pactl list sinks | grep -A 15 \"* index\" | grep Volume | head -n 1 | awk '{print $5}'")
			pulseOut, err := pulseCmd.Output()
			if err == nil {
				fmt.Printf("• PulseAudio: %s", string(pulseOut))
			} else {
				color.Red("Error getting PulseAudio volume: %v", err)
			}

			// Get ALSA mixer volume
			alsaCmd := exec.Command("bash", "-c", "amixer -c 0 get PCM | grep \"Mono:\" | awk '{print $3}'")
			alsaOut, err := alsaCmd.Output()
			if err == nil {
				fmt.Printf("• ALSA: %s", string(alsaOut))
			} else {
				color.Red("Error getting ALSA volume: %v", err)
			}
		},
	}
} 