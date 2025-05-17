package cmd

import (
	"fmt"
	"net"
	"os/exec"
	"strings"

	"github.com/nicohoff/network_utils/internal/utils"
	"github.com/spf13/cobra"
)

func newLookupCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "lookup <hostname/IP> [type]",
		Short: "Perform DNS lookups",
		Long:  `Perform DNS lookups for various record types`,
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			target := args[0]
			recordType := "a"
			if len(args) > 1 {
				recordType = strings.ToLower(args[1])
			}
			
			runLookup(target, recordType)
		},
	}

	return cmd
}

func runLookup(target, recordType string) {
	recordTypeUpper := strings.ToUpper(recordType)
	
	utils.PrintBlue("\n=== DNS Lookup ===")
	utils.PrintCyan(fmt.Sprintf("Target: %s", target))
	utils.PrintCyan(fmt.Sprintf("Record type: %s\n", recordTypeUpper))
	
	// Standard lookup using Go's net package
	utils.PrintYellow("Standard Lookup:")
	
	var results []string
	var err error
	
	switch recordType {
	case "a":
		ips, err := net.LookupIP(target)
		if err == nil {
			for _, ip := range ips {
				if ip.To4() != nil { // Only IPv4 addresses
					results = append(results, fmt.Sprintf("%s has address %s", target, ip.String()))
				}
			}
		}
	case "aaaa":
		ips, err := net.LookupIP(target)
		if err == nil {
			for _, ip := range ips {
				if ip.To4() == nil && ip.To16() != nil { // Only IPv6 addresses
					results = append(results, fmt.Sprintf("%s has IPv6 address %s", target, ip.String()))
				}
			}
		}
	case "mx":
		mxs, err := net.LookupMX(target)
		if err == nil {
			for _, mx := range mxs {
				results = append(results, fmt.Sprintf("%s mail is handled by %d %s", target, mx.Pref, mx.Host))
			}
		}
	case "ns":
		nss, err := net.LookupNS(target)
		if err == nil {
			for _, ns := range nss {
				results = append(results, fmt.Sprintf("%s name server %s", target, ns.Host))
			}
		}
	case "txt":
		txts, err := net.LookupTXT(target)
		if err == nil {
			for _, txt := range txts {
				results = append(results, fmt.Sprintf("%s descriptive text \"%s\"", target, txt))
			}
		}
	case "any", "all":
		// For "any", use 'host -a' command since Go doesn't directly support ANY queries
		cmd := exec.Command("host", "-a", target)
		output, err := cmd.Output()
		if err == nil {
			fmt.Println(string(output))
		} else {
			// Fallback to multiple individual lookups
			runLookup(target, "a")
			runLookup(target, "aaaa")
			runLookup(target, "mx")
			runLookup(target, "ns")
			runLookup(target, "txt")
			return
		}
	default:
		// Default to A record lookup
		ips, err := net.LookupIP(target)
		if err == nil {
			for _, ip := range ips {
				if ip.To4() != nil {
					results = append(results, fmt.Sprintf("%s has address %s", target, ip.String()))
				}
			}
		}
	}
	
	if err != nil {
		utils.PrintRed(fmt.Sprintf("Error: %v", err))
	} else if len(results) == 0 && recordType != "any" && recordType != "all" {
		utils.PrintYellow(fmt.Sprintf("No %s records found for %s", recordTypeUpper, target))
	} else {
		for _, result := range results {
			fmt.Println(result)
		}
	}
	
	// Reverse lookup if IP
	if net.ParseIP(target) != nil {
		utils.PrintYellow("\nReverse Lookup:")
		names, err := net.LookupAddr(target)
		if err != nil {
			utils.PrintRed(fmt.Sprintf("Error: %v", err))
		} else if len(names) == 0 {
			utils.PrintYellow("No PTR record found")
		} else {
			for _, name := range names {
				fmt.Printf("%s domain name pointer %s\n", target, name)
			}
		}
	}
	
	// If dig is available, show detailed information
	if _, err := exec.LookPath("dig"); err == nil {
		utils.PrintYellow("\nDetailed Information (dig):")
		var args []string
		
		if recordType == "any" || recordType == "all" {
			args = []string{target, "ANY", "+short"}
		} else {
			args = []string{target, recordTypeUpper, "+short"}
		}
		
		cmd := exec.Command("dig", args...)
		output, err := cmd.Output()
		if err != nil {
			utils.PrintRed(fmt.Sprintf("Error running dig: %v", err))
		} else if len(output) == 0 {
			utils.PrintYellow("No records found")
		} else {
			fmt.Println(string(output))
		}
	}
} 