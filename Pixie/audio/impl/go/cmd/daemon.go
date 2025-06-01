package cmd

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"syscall"
	"time"

	"github.com/spf13/cobra"
)

var daemonCmd = &cobra.Command{
	Use:   "daemon",
	Short: "Run the Pixie Audio daemon",
	Run: func(cmd *cobra.Command, args []string) {
		runDaemon()
	},
}

func init() {
	rootCmd.AddCommand(daemonCmd)
}

func runDaemon() {
	// Ensure PulseAudio is running
	if err := ensurePulseAudio(); err != nil {
		log.Fatalf("Failed to start PulseAudio: %v", err)
	}

	// Start Shairport-sync
	if err := startShairportSync(); err != nil {
		log.Printf("Warning: Failed to start Shairport-sync: %v", err)
	}

	// Start Librespot
	if err := startLibrespot(); err != nil {
		log.Printf("Warning: Failed to start Librespot: %v", err)
	}

	// Start Bluetooth
	if err := startBluetooth(); err != nil {
		log.Printf("Warning: Failed to start Bluetooth: %v", err)
	}

	// Keep the daemon running and monitor services
	for {
		time.Sleep(30 * time.Second)
		checkServices()
	}
}

func ensurePulseAudio() error {
	cmd := exec.Command("systemctl", "is-active", "pulseaudio-system.service")
	if err := cmd.Run(); err != nil {
		cmd = exec.Command("systemctl", "start", "pulseaudio-system.service")
		return cmd.Run()
	}
	return nil
}

func startShairportSync() error {
	cmd := exec.Command("systemctl", "start", "shairport-sync.service")
	return cmd.Run()
}

func startLibrespot() error {
	cmd := exec.Command("systemctl", "start", "librespot.service")
	return cmd.Run()
}

func startBluetooth() error {
	cmd := exec.Command("systemctl", "start", "bluetooth-boot.service")
	return cmd.Run()
}

func checkServices() {
	services := []string{
		"pulseaudio-system.service",
		"shairport-sync.service",
		"librespot.service",
		"bluetooth-boot.service",
	}

	for _, service := range services {
		cmd := exec.Command("systemctl", "is-active", service)
		if err := cmd.Run(); err != nil {
			log.Printf("Service %s is not running, attempting to restart", service)
			restartCmd := exec.Command("systemctl", "restart", service)
			if err := restartCmd.Run(); err != nil {
				log.Printf("Failed to restart %s: %v", service, err)
			}
		}
	}
} 