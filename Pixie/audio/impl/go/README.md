# Pixie Audio - Go Implementation

This directory contains a Go implementation of the Pixie audio control system, which provides the same functionality as the original shell script implementation but with the advantages of a compiled language.

## Features

- **Setup**: Configure the Pixie audio middleware architecture
- **Status**: Show the current status of audio components and streams
- **Control**: Manage audio services and volume levels
- **Health**: Run diagnostics on the audio system
- **Bluetooth**: Manage Bluetooth audio connections
- **Volume**: Control system volume

## Building

Build the application with:

```bash
cd Pixie/audio-go
go build -o pixie-audio
```

## Installation

After building, you can install the binary:

```bash
sudo cp pixie-audio /usr/local/bin/
```

## Usage

```
# Setup the audio system
pixie-audio setup

# Check the status of audio components
pixie-audio status

# Control audio services
pixie-audio control restart                  # Restart audio services
pixie-audio control spotify-volume 80        # Set Spotify volume to 80%
pixie-audio control airplay-volume 90        # Set AirPlay volume to 90%

# Run health check
pixie-audio health

# Manage Bluetooth
pixie-audio bluetooth setup                  # Configure Bluetooth
pixie-audio bluetooth list                   # List paired devices
pixie-audio bluetooth scan                   # Scan for devices
pixie-audio bluetooth pair XX:XX:XX:XX:XX:XX # Pair with a device
pixie-audio bluetooth connect XX:XX:XX:XX:XX:XX # Connect to a device
pixie-audio bluetooth disconnect             # Disconnect from device

# Control volume
pixie-audio volume ensure                    # Set master volume to 100%
pixie-audio volume set 80                    # Set master volume to 80%
pixie-audio volume get                       # Show current volume
```

## Advantages Over Shell Scripts

1. **Type Safety**: Go's type system prevents many errors at compile time
2. **Single Binary**: All functionality is packaged in a single binary
3. **Structured Command Interface**: More intuitive command structure
4. **Improved Error Handling**: Better error handling and reporting
5. **Cross-Compilation**: Can be compiled for different platforms
6. **Maintainability**: Easier to maintain and extend with new features

## Notes

This implementation provides the same functionality as the original shell scripts while maintaining compatibility with the existing configuration files. It does not replace the original scripts but provides an alternative implementation. 