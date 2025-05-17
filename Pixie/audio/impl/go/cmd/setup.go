package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

func newSetupCmd() *cobra.Command {
	setupCmd := &cobra.Command{
		Use:   "setup",
		Short: "Setup the audio middleware architecture",
		Long: `Setup the Pixie Audio Middleware Architecture.
This will configure:
- PulseAudio system instance as the audio middleware
- Shairport Sync (AirPlay) for streaming from iOS/macOS
- Librespot (Spotify Connect) for streaming from Spotify
- Bluetooth A2DP for streaming from any Bluetooth device`,
		Run: runSetupCmd,
	}

	setupCmd.Flags().BoolP("yes", "y", false, "Automatically answer yes to all prompts")

	return setupCmd
}

func runSetupCmd(cmd *cobra.Command, args []string) {
	yes, _ := cmd.Flags().GetBool("yes")

	color.Blue("Setting up Audio Middleware Architecture for Pixie...")
	fmt.Println("")
	fmt.Println("This setup will configure:")
	fmt.Println("  - PulseAudio system instance as the audio middleware")
	fmt.Println("  - Shairport Sync (AirPlay) for streaming from iOS/macOS")
	fmt.Println("  - Librespot (Spotify Connect) for streaming from Spotify")
	fmt.Println("  - Bluetooth A2DP for streaming from any Bluetooth device")
	fmt.Println("")

	if !yes {
		fmt.Print("Do you want to continue? [y/N] ")
		reader := bufio.NewReader(os.Stdin)
		response, _ := reader.ReadString('\n')
		response = strings.ToLower(strings.TrimSpace(response))

		if response != "y" && response != "yes" {
			color.Yellow("Setup cancelled.")
			return
		}
	}

	// Create necessary directories
	fmt.Println("Creating necessary directories...")
	os.MkdirAll("/home/pi/bin", 0755)

	// Install helper scripts
	fmt.Println("Installing helper scripts...")
	copyFile("impl/shell/scripts/ensure-master-volume.sh", "/home/pi/bin/")
	copyFile("impl/shell/scripts/audio-status.sh", "/home/pi/bin/")
	copyFile("impl/shell/scripts/audio-control.sh", "/home/pi/bin/")
	os.Chmod("/home/pi/bin/ensure-master-volume.sh", 0755)
	os.Chmod("/home/pi/bin/audio-status.sh", 0755)
	os.Chmod("/home/pi/bin/audio-control.sh", 0755)

	// Install and enable services
	fmt.Println("Installing systemd services...")
	execCommand("sudo", "cp", "config/shairport-sync.service", "/etc/systemd/system/")
	execCommand("sudo", "cp", "config/librespot.service", "/etc/systemd/system/")
	execCommand("sudo", "cp", "systemd/ensure-master-volume.service", "/etc/systemd/system/")
	execCommand("sudo", "cp", "systemd/ensure-master-volume.timer", "/etc/systemd/system/")

	// Configure shairport-sync
	fmt.Println("Updating shairport-sync configuration...")
	shairportConfig := `general = {
    name = "Pixie";
    output_backend = "pa";
};

pa = {
    application_name = "Shairport Sync";
};
`
	tmpFile, _ := os.CreateTemp("", "shairport-sync.conf")
	tmpFile.WriteString(shairportConfig)
	tmpFile.Close()
	execCommand("sudo", "bash", "-c", fmt.Sprintf("cat %s >> /etc/shairport-sync.conf", tmpFile.Name()))
	os.Remove(tmpFile.Name())

	// Set initial volume
	fmt.Println("Setting initial volume...")
	execCommand("sudo", "-u", "pulse", "pactl", "set-sink-volume", "@DEFAULT_SINK@", "100%")

	// Set up Bluetooth
	fmt.Println("")
	fmt.Println("Setting up Bluetooth audio...")
	execCommand("bash", "config/bluetooth-setup.sh")

	// Enable and start services
	fmt.Println("Enabling and starting services...")
	execCommand("sudo", "systemctl", "daemon-reload")
	execCommand("sudo", "systemctl", "enable", "shairport-sync.service")
	execCommand("sudo", "systemctl", "enable", "librespot.service")
	execCommand("sudo", "systemctl", "enable", "ensure-master-volume.timer")

	fmt.Println("Starting services...")
	execCommand("sudo", "systemctl", "restart", "shairport-sync.service")
	execCommand("sudo", "systemctl", "restart", "librespot.service")
	execCommand("sudo", "systemctl", "start", "ensure-master-volume.timer")

	fmt.Println("")
	color.Blue("=====================================================================")
	color.Green("Setup complete! Your Pixie audio middleware is now configured.")
	color.Blue("=====================================================================")
	fmt.Println("")
	fmt.Println("You can now stream audio to Pixie using:")
	fmt.Println("  - AirPlay from iOS/macOS devices")
	fmt.Println("  - Spotify Connect from any device")
	fmt.Println("  - Bluetooth from any paired device")
	fmt.Println("")
	fmt.Println("To check the status of your audio system, run: pixie-audio status")
	fmt.Println("To control audio services, run: pixie-audio control [command]")
	fmt.Println("To manually configure Bluetooth, run: pixie-audio bluetooth setup")
	fmt.Println("")
	color.Green("Enjoy your music!")
}

// Helper function to copy files
func copyFile(src, dest string) error {
	// Determine if dest is a directory
	destInfo, err := os.Stat(dest)
	if err == nil && destInfo.IsDir() {
		dest = filepath.Join(dest, filepath.Base(src))
	}

	// Get absolute path for src
	srcPath := src
	if !filepath.IsAbs(src) {
		srcPath = filepath.Join("/home/pi/Desktop/nico-hoff/Pixie/audio", src)
	}

	// Run cp command
	return execCommand("cp", srcPath, dest)
}

// Helper function to execute commands
func execCommand(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
} 