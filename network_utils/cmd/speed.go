package cmd

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/nicohoff/network_utils/internal/utils"
	"github.com/spf13/cobra"
)

func newSpeedCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "speed",
		Short: "Test download/upload speeds",
		Long:  `Test download/upload speeds using various file sizes`,
		Run: func(cmd *cobra.Command, args []string) {
			runSpeed()
		},
	}

	return cmd
}

func runSpeed() {
	utils.PrintBlue("\n=== Network Speed Test ===")
	
	// Check if curl is available
	if _, err := exec.LookPath("curl"); err != nil {
		utils.PrintYellow("Warning: curl is not installed. Using Go's HTTP client for speed tests.")
	}
	
	// Use Cloudflare's speed test files
	sizes := []struct {
		Name string
		URL  string
		Size int64 // size in bytes
	}{
		{"100KB", "https://speed.cloudflare.com/100kb.bin", 100 * 1024},
		{"1MB", "https://speed.cloudflare.com/1mb.bin", 1024 * 1024},
		{"10MB", "https://speed.cloudflare.com/10mb.bin", 10 * 1024 * 1024},
		{"100MB", "https://speed.cloudflare.com/100mb.bin", 100 * 1024 * 1024},
	}
	
	// Create temp directory for downloads
	tempDir, err := os.MkdirTemp("", "speedtest")
	if err != nil {
		utils.PrintRed(fmt.Sprintf("Error creating temporary directory: %v", err))
		return
	}
	defer os.RemoveAll(tempDir)
	
	for _, size := range sizes {
		outputFile := fmt.Sprintf("%s/speedtest_%s", tempDir, size.Name)
		
		utils.PrintCyan(fmt.Sprintf("\nTesting download speed (%s file)...", size.Name))
		
		// Perform 3 downloads and take the average
		var totalSpeed float64
		var successfulTests int
		
		for test := 1; test <= 3; test++ {
			fmt.Printf("\nTest %d of 3: ", test)
			
			// Test download speed
			speed, err := testDownloadSpeed(size.URL, outputFile, size.Size)
			if err != nil {
				fmt.Printf("Failed (%v)", err)
			} else {
				fmt.Printf("%.2f Mbps", speed)
				totalSpeed += speed
				successfulTests++
			}
			
			// Clean up downloaded file
			os.Remove(outputFile)
			
			// Small delay between tests
			time.Sleep(time.Second)
		}
		
		// Calculate and display average speed
		if successfulTests > 0 {
			avgSpeed := totalSpeed / float64(successfulTests)
			fmt.Printf("\nAverage download speed: \033[0;32m%.2f Mbps\033[0m\n", avgSpeed)
		} else {
			utils.PrintRed("\nAll tests failed for this file size.")
		}
	}
	
	// Test latency to common servers
	utils.PrintCyan("\nTesting latency...")
	servers := []string{"8.8.8.8", "1.1.1.1", "9.9.9.9"}
	
	for _, server := range servers {
		pingCmd := exec.Command("ping", "-c", "5", "-q", server)
		output, err := pingCmd.CombinedOutput()
		if err == nil {
			lines := strings.Split(string(output), "\n")
			for _, line := range lines {
				if strings.Contains(line, "min/avg/max") {
					fmt.Printf("  %s: %s\n", server, line)
					break
				}
			}
		} else {
			fmt.Printf("  %s: Error - %v\n", server, err)
		}
	}
	
	fmt.Println() // Add a newline at the end
}

// testDownloadSpeed downloads a file and measures the download speed
func testDownloadSpeed(url, outputFile string, expectedSize int64) (float64, error) {
	start := time.Now()
	
	// Try using curl if available for more accurate results
	if _, err := exec.LookPath("curl"); err == nil {
		cmd := exec.Command("curl", "-s", "-o", outputFile, "-w", "%{speed_download}", url)
		output, err := cmd.Output()
		if err != nil {
			return 0, err
		}
		
		// Parse the speed output from curl
		speedStr := strings.TrimSpace(string(output))
		speed, err := strconv.ParseFloat(speedStr, 64)
		if err != nil {
			return 0, err
		}
		
		// Convert B/s to Mbps (bits per second)
		return speed * 8 / 1000000, nil
	}
	
	// Fallback to Go's HTTP client
	resp, err := http.Get(url)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	
	file, err := os.Create(outputFile)
	if err != nil {
		return 0, err
	}
	defer file.Close()
	
	written, err := io.Copy(file, resp.Body)
	if err != nil {
		return 0, err
	}
	
	elapsed := time.Since(start).Seconds()
	
	// Check if we got the expected amount of data
	if written != expectedSize {
		return 0, fmt.Errorf("expected %d bytes, got %d", expectedSize, written)
	}
	
	// Calculate speed in Mbps (megabits per second)
	// Convert bytes to bits (multiply by 8) and divide by elapsed time in seconds
	// Then convert to megabits by dividing by 1,000,000
	speedMbps := float64(written) * 8 / elapsed / 1000000
	
	return speedMbps, nil
} 