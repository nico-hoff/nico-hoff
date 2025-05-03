# Spotify Connect Setup

## Overview
A systemd service has been configured to run librespot, allowing the Raspberry Pi to function as a Spotify Connect device under the name "Pixie".

## Configuration Details

### Service Configuration
The service is configured in `/etc/systemd/system/librespot.service`:

```
[Unit]
Description=Librespot Spotify Connect client
After=network.target sound.target
Wants=network.target sound.target

[Service]
Type=simple
User=pi
ExecStart=/home/pi/.cargo/bin/librespot --name "Pixie" --bitrate 320 --enable-volume-normalisation --initial-volume 60
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Parameters
- `--name "Pixie"`: Sets the device name visible in Spotify clients
- `--bitrate 320`: Uses 320 kbps audio quality
- `--enable-volume-normalisation`: Enables volume normalization
- `--initial-volume 60`: Sets initial volume to 60%

## Management Commands

- Check service status: `systemctl status librespot.service`
- Start service: `sudo systemctl start librespot.service`
- Stop service: `sudo systemctl stop librespot.service`
- Restart service: `sudo systemctl restart librespot.service`
- Enable at boot: `sudo systemctl enable librespot.service`
- Disable at boot: `sudo systemctl disable librespot.service` 