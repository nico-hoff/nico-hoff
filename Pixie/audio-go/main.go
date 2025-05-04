package main

import (
	"fmt"
	"os"

	"github.com/nico-hoff/pixie/audio-go/cmd"
)

func main() {
	rootCmd := cmd.NewRootCmd()
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
} 