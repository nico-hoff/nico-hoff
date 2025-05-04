# Default Volume Setup

## Overview
Multiple approaches have been implemented to ensure the system volume is set to 100% at boot time.

## Implemented Solutions

### 1. rc.local Method
A script has been added to `/etc/rc.local` that sets the system volume to 100% at boot time:

```bash
# Set default audio volume to 100%
amixer sset Master 100% || pactl set-sink-volume @DEFAULT_SINK@ 100% || true
```

This approach tries both ALSA (amixer) and PulseAudio (pactl) methods to ensure compatibility.

### 2. User Login Autostart
A desktop entry has been created at `/home/pi/.config/autostart/set-volume.desktop` to set the volume when the user logs in:

```
[Desktop Entry]
Type=Application
Name=Set Volume
Exec=/home/pi/set-volume.sh
Terminal=false
X-GNOME-Autostart-enabled=true
```

The script `/home/pi/set-volume.sh` contains:
```bash
#!/bin/bash
# Set volume to 100% using pactl
pactl set-sink-volume @DEFAULT_SINK@ 100%
```

### 3. Systemd Service
A systemd service has been configured at `/etc/systemd/system/set-volume.service`:

```
[Unit]
Description=Set System Volume to 100%
After=pulseaudio.service
Requires=pulseaudio.service

[Service]
Type=oneshot
ExecStart=/home/pi/set-volume.sh
User=pi

[Install]
WantedBy=multi-user.target
```

## Notes
- The rc.local method is the most reliable as it tries multiple volume control approaches
- The autostart method works when a user logs in to the desktop environment
- The systemd service depends on PulseAudio being available as a system service 