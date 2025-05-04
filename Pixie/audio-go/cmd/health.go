package cmd

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

func newHealthCmd() *cobra.Command {
	healthCmd := &cobra.Command{
		Use:   "health",
		Short: "Check the health of audio systems",
		Long:  `Run diagnostics to check if all audio-related systems are available and functioning.`,
		Run:   runHealthCmd,
	}
	return healthCmd
}

func runHealthCmd(cmd *cobra.Command, args []string) {
	blue := color.New(color.FgBlue).SprintFunc()
	green := color.New(color.FgGreen).SprintFunc()
	red := color.New(color.FgRed).SprintFunc()
	yellow := color.New(color.FgYellow).SprintFunc()

	fmt.Printf("%s\n", blue("====== Pixie Audio Health Check ====="))
	fmt.Println("Checking all audio systems...")
	fmt.Println("")

	totalChecks := 0
	failedChecks := 0
	var shairportStatus, librespotStatus string

	// Check audio devices
	fmt.Printf("%s\n", blue("== Core Audio System =="))
	fmt.Print("Checking ALSA audio devices... ")
	
	alsaCmd := exec.Command("bash", "-c", "aplay -l | grep 'bcm2835 ALSA'")
	if err := alsaCmd.Run(); err != nil {
		fmt.Printf("%s\n", red("NOT FOUND"))
		failedChecks++
	} else {
		fmt.Printf("%s\n", green("FOUND"))
	}
	totalChecks++

	// Check PulseAudio process
	fmt.Print("Checking PulseAudio process... ")
	pulseCmd := exec.Command("bash", "-c", "pgrep -f pulseaudio")
	if err := pulseCmd.Run(); err != nil {
		fmt.Printf("%s\n", red("NOT RUNNING"))
		failedChecks++
	} else {
		fmt.Printf("%s\n", green("RUNNING"))
	}
	totalChecks++

	// Check PulseAudio modules
	fmt.Printf("\n%s\n", blue("== PulseAudio Configuration =="))
	
	// Check ALSA module
	checkPulseModule("module-alsa", "ALSA module")
	
	// Check Bluetooth module
	checkPulseModule("module-bluetooth", "Bluetooth module")
	
	// Check Unix protocol module
	checkPulseModule("module-native-protocol-unix", "Unix protocol module")

	// Check audio services
	fmt.Printf("\n%s\n", blue("== Audio Services =="))
	
	// Check Shairport service
	shairportCmd := exec.Command("systemctl", "is-active", "shairport-sync.service")
	shairportOutput, _ := shairportCmd.Output()
	shairportStatus = strings.TrimSpace(string(shairportOutput))
	
	fmt.Print("Checking Shairport Sync (AirPlay)... ")
	if shairportStatus == "active" {
		fmt.Printf("%s\n", green("RUNNING"))
	} else {
		fmt.Printf("%s\n", red("NOT RUNNING"))
		failedChecks++
	}
	totalChecks++

	// Check Librespot service
	librespotCmd := exec.Command("systemctl", "is-active", "librespot.service")
	librespotOutput, _ := librespotCmd.Output()
	librespotStatus = strings.TrimSpace(string(librespotOutput))
	
	fmt.Print("Checking Librespot (Spotify)... ")
	if librespotStatus == "active" {
		fmt.Printf("%s\n", green("RUNNING"))
	} else {
		fmt.Printf("%s\n", red("NOT RUNNING"))
		failedChecks++
	}
	totalChecks++

	// Check volume service
	fmt.Print("Checking Master Volume Service... ")
	volumeCmd := exec.Command("systemctl", "is-active", "ensure-master-volume.timer")
	volumeOutput, _ := volumeCmd.Output()
	volumeStatus := strings.TrimSpace(string(volumeOutput))
	
	if volumeStatus == "active" {
		fmt.Printf("%s\n", green("RUNNING"))
	} else {
		fmt.Printf("%s\n", red("NOT RUNNING"))
		failedChecks++
	}
	totalChecks++

	// Check Bluetooth configuration
	fmt.Printf("\n%s\n", blue("== Bluetooth Configuration =="))
	
	// Check Bluetooth adapter
	fmt.Print("Checking Bluetooth adapter... ")
	btAdapterCmd := exec.Command("bash", "-c", "hciconfig hci0 up")
	if err := btAdapterCmd.Run(); err != nil {
		fmt.Printf("%s\n", red("NOT AVAILABLE"))
		failedChecks++
	} else {
		fmt.Printf("%s\n", green("AVAILABLE"))
		
		// Check Bluetooth class if adapter is available
		fmt.Print("Checking Bluetooth audio class... ")
		btClassCmd := exec.Command("bash", "-c", "hciconfig hci0 | grep \"Class\" | awk '{print $2}'")
		btClassOutput, _ := btClassCmd.Output()
		btClass := strings.TrimSpace(string(btClassOutput))
		
		if btClass == "0x240414" {
			fmt.Printf("%s\n", green("CORRECT (Audio Sink)"))
		} else {
			fmt.Printf("%s\n", yellow("INCORRECT ("+btClass+")"))
			failedChecks++
		}
	}
	totalChecks++

	// Check Bluetooth services
	fmt.Print("Checking Bluetooth service... ")
	checkServiceStatus("bluetooth.service")
	
	fmt.Print("Checking Bluetooth boot service... ")
	checkServiceStatus("bluetooth-boot.service")
	
	fmt.Print("Checking A2DP agent service... ")
	checkServiceStatus("a2dp-agent.service")
	
	fmt.Print("Checking Bluetooth simple agent... ")
	checkServiceStatus("simple-agent.service")

	// Check boot configuration
	fmt.Printf("\n%s\n", blue("== Boot Configuration =="))
	
	fmt.Print("Checking if Shairport Sync (AirPlay) starts at boot... ")
	checkServiceEnabled("shairport-sync.service")
	
	fmt.Print("Checking if Librespot (Spotify) starts at boot... ")
	checkServiceEnabled("librespot.service")
	
	fmt.Print("Checking if Bluetooth service starts at boot... ")
	checkServiceEnabled("bluetooth.service")
	
	fmt.Print("Checking if Bluetooth boot service starts at boot... ")
	checkServiceEnabled("bluetooth-boot.service")
	
	fmt.Print("Checking if A2DP agent starts at boot... ")
	checkServiceEnabled("a2dp-agent.service")
	
	fmt.Print("Checking if Bluetooth simple agent starts at boot... ")
	checkServiceEnabled("simple-agent.service")

	// Check logs for errors
	fmt.Printf("\n%s\n", blue("== Log Analysis =="))
	fmt.Println("Checking for errors in logs...")
	
	// Check PulseAudio logs
	fmt.Print("PulseAudio issues: ")
	pulseErrorsCmd := exec.Command("bash", "-c", "journalctl -u pulseaudio --since \"1 hour ago\" | grep -i \"error\\|fail\" | wc -l")
	pulseErrorsOutput, _ := pulseErrorsCmd.Output()
	pulseErrors, _ := strconv.Atoi(strings.TrimSpace(string(pulseErrorsOutput)))
	
	if pulseErrors > 0 {
		fmt.Printf("%s\n", yellow(fmt.Sprintf("%d errors found", pulseErrors)))
		fmt.Println("Run 'journalctl -u pulseaudio | grep -i \"error\\|fail\"' for details")
	} else {
		fmt.Printf("%s\n", green("None"))
	}
	
	// Check Shairport logs
	fmt.Print("Shairport issues: ")
	shairportErrorsCmd := exec.Command("bash", "-c", "journalctl -u shairport-sync --since \"1 hour ago\" | grep -i \"error\\|fail\" | wc -l")
	shairportErrorsOutput, _ := shairportErrorsCmd.Output()
	shairportErrors, _ := strconv.Atoi(strings.TrimSpace(string(shairportErrorsOutput)))
	
	if shairportErrors > 0 {
		fmt.Printf("%s\n", yellow(fmt.Sprintf("%d errors found", shairportErrors)))
		fmt.Println("Run 'journalctl -u shairport-sync | grep -i \"error\\|fail\"' for details")
	} else {
		fmt.Printf("%s\n", green("None"))
	}
	
	// Check Librespot logs
	fmt.Print("Librespot issues: ")
	librespotErrorsCmd := exec.Command("bash", "-c", "journalctl -u librespot --since \"1 hour ago\" | grep -i \"error\\|fail\" | wc -l")
	librespotErrorsOutput, _ := librespotErrorsCmd.Output()
	librespotErrors, _ := strconv.Atoi(strings.TrimSpace(string(librespotErrorsOutput)))
	
	if librespotErrors > 0 {
		fmt.Printf("%s\n", yellow(fmt.Sprintf("%d errors found", librespotErrors)))
		fmt.Println("Run 'journalctl -u librespot | grep -i \"error\\|fail\"' for details")
	} else {
		fmt.Printf("%s\n", green("None"))
	}
	
	// Check Bluetooth logs
	fmt.Print("Bluetooth issues: ")
	btErrorsCmd := exec.Command("bash", "-c", "journalctl -u bluetooth --since \"1 hour ago\" | grep -i \"error\\|fail\" | wc -l")
	btErrorsOutput, _ := btErrorsCmd.Output()
	btErrors, _ := strconv.Atoi(strings.TrimSpace(string(btErrorsOutput)))
	
	if btErrors > 0 {
		fmt.Printf("%s\n", yellow(fmt.Sprintf("%d errors found", btErrors)))
		fmt.Println("Run 'journalctl -u bluetooth | grep -i \"error\\|fail\"' for details")
	} else {
		fmt.Printf("%s\n", green("None"))
	}

	// Print summary
	fmt.Printf("\n%s\n", blue("====== Summary ======"))
	
	if shairportStatus == "active" {
		fmt.Printf("AirPlay: %s\n", green("AVAILABLE"))
	} else {
		fmt.Printf("AirPlay: %s\n", red("NOT AVAILABLE"))
	}
	
	if librespotStatus == "active" {
		fmt.Printf("Spotify Connect: %s\n", green("AVAILABLE"))
	} else {
		fmt.Printf("Spotify Connect: %s\n", red("NOT AVAILABLE"))
	}
	
	// Check Bluetooth comprehensive status
	btServices := []string{"bluetooth.service", "bluetooth-boot.service", "a2dp-agent.service", "simple-agent.service"}
	allBtServicesActive := true
	
	for _, service := range btServices {
		statusCmd := exec.Command("systemctl", "is-active", service)
		statusOutput, _ := statusCmd.Output()
		status := strings.TrimSpace(string(statusOutput))
		
		if status != "active" {
			allBtServicesActive = false
			break
		}
	}
	
	if allBtServicesActive {
		fmt.Printf("Bluetooth: %s\n", green("AVAILABLE"))
	} else {
		fmt.Printf("Bluetooth: %s\n", red("NOT FULLY AVAILABLE"))
	}
	
	// Calculate success rate
	successRate := 100 - (failedChecks * 100 / totalChecks)
	fmt.Printf("Audio Services Health: %d%% operational\n", successRate)

	fmt.Println("\nFor detailed status information, run:")
	fmt.Println("  pixie-audio status")
	fmt.Println("To control audio services, run:")
	fmt.Println("  pixie-audio control [command]")
	fmt.Println("To manually configure Bluetooth, run:")
	fmt.Println("  pixie-audio bluetooth setup")
}

// Helper function to check PulseAudio module status
func checkPulseModule(moduleName, moduleDesc string) {
	fmt.Printf("Checking PulseAudio %s... ", moduleDesc)
	
	cmd := exec.Command("bash", "-c", fmt.Sprintf("sudo -u pulse pactl list modules | grep \"%s\"", moduleName))
	if err := cmd.Run(); err != nil {
		fmt.Printf("%s\n", color.RedString("NOT LOADED"))
	} else {
		fmt.Printf("%s\n", color.GreenString("LOADED"))
	}
}

// Helper function to check service status
func checkServiceStatus(serviceName string) {
	cmd := exec.Command("systemctl", "is-active", serviceName)
	output, _ := cmd.Output()
	status := strings.TrimSpace(string(output))
	
	if status == "active" {
		fmt.Printf("%s\n", color.GreenString("RUNNING"))
	} else {
		fmt.Printf("%s\n", color.RedString("NOT RUNNING"))
	}
}

// Helper function to check if service is enabled
func checkServiceEnabled(serviceName string) {
	cmd := exec.Command("systemctl", "is-enabled", serviceName)
	output, _ := cmd.Output()
	status := strings.TrimSpace(string(output))
	
	if status == "enabled" {
		fmt.Printf("%s\n", color.GreenString("ENABLED"))
	} else {
		fmt.Printf("%s\n", color.YellowString("NOT ENABLED"))
	}
} 