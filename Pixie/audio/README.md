# Pixie Audio System

This directory contains the audio control system for Pixie, with two implementations available:

## Directory Structure

```
audio/
├── README.md           # This file
├── config/            # Configuration files for audio services
├── docs/             # Documentation
├── impl/             # Implementation directory
│   ├── go/          # Go implementation
│   │   ├── cmd/     # Command implementations
│   │   ├── main.go  # Main entry point
│   │   └── ...      # Other Go files
│   └── shell/       # Shell script implementation
│       ├── scripts/ # Shell scripts
│       └── setup.sh # Main setup script
├── scripts/          # Legacy scripts (will be moved to impl/shell)
└── systemd/         # Systemd service files
```

## Implementations

### Go Implementation (Recommended)

The Go implementation (`impl/go`) provides a modern, type-safe interface to the audio system. It offers:

- Type safety and better error handling
- Single binary distribution
- Structured command interface
- Cross-compilation support
- Improved maintainability

To use the Go implementation:

```bash
# Build
cd audio/impl/go
go build -o pixie-audio

# Install
sudo cp pixie-audio /usr/local/bin/

# Usage
pixie-audio setup
pixie-audio status
pixie-audio control [command]
pixie-audio bluetooth [command]
pixie-audio volume [command]
```

### Shell Script Implementation

The shell script implementation (`impl/shell`) provides the original interface using bash scripts. It's useful for:

- Direct script modification
- Understanding the underlying system
- Quick modifications without recompilation

To use the shell implementation:

```bash
# Setup
./impl/shell/setup.sh

# Status
./impl/shell/scripts/audio-status.sh

# Control
./impl/shell/scripts/audio-control.sh
```

## Shared Components

Both implementations share:
- Configuration files in `config/`
- Systemd service files in `systemd/`
- Documentation in `docs/`

## Features

Both implementations provide:
- Audio middleware setup (PulseAudio)
- AirPlay support (Shairport Sync)
- Spotify Connect (Librespot)
- Bluetooth audio
- Volume control
- System status monitoring
- Service management

## Development

When making changes:
1. Update shared configuration files in `config/` and `systemd/`
2. Update both implementations to maintain compatibility
3. Update documentation in `docs/`
4. Test both implementations 