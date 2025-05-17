#!/bin/bash

set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up Audio Middleware Architecture for Pixie..."
echo ""
echo "This setup will configure:"
echo "  - PulseAudio system instance as the audio middleware"
echo "  - Shairport Sync (AirPlay) for streaming from iOS/macOS"
echo "  - Librespot (Spotify Connect) for streaming from Spotify"
echo "  - Bluetooth A2DP for streaming from any Bluetooth device"
echo ""
read -p "Do you want to continue? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Create necessary directories
mkdir -p /home/pi/bin

# Install helper scripts
echo "Installing helper scripts..."
cp $SCRIPT_DIR/scripts/ensure-master-volume.sh /home/pi/bin/
cp $SCRIPT_DIR/scripts/audio-status.sh /home/pi/bin/
cp $SCRIPT_DIR/scripts/audio-control.sh /home/pi/bin/
chmod +x /home/pi/bin/ensure-master-volume.sh
chmod +x /home/pi/bin/audio-status.sh
chmod +x /home/pi/bin/audio-control.sh

# Install and enable services
echo "Installing systemd services..."
sudo cp $SCRIPT_DIR/config/shairport-sync.service /etc/systemd/system/
sudo cp $SCRIPT_DIR/config/librespot.service /etc/systemd/system/
sudo cp $SCRIPT_DIR/systemd/ensure-master-volume.service /etc/systemd/system/
sudo cp $SCRIPT_DIR/systemd/ensure-master-volume.timer /etc/systemd/system/

# Configure shairport-sync
echo "Updating shairport-sync configuration..."
cat > /tmp/shairport-sync.conf.update << EOL
general = {
    name = "Pixie";
    output_backend = "pa";
};

pa = {
    application_name = "Shairport Sync";
};
EOL
sudo bash -c 'cat /tmp/shairport-sync.conf.update >> /etc/shairport-sync.conf'

# Set initial volume
echo "Setting initial volume..."
sudo -u pulse pactl set-sink-volume @DEFAULT_SINK@ 100%

# Set up Bluetooth
echo ""
echo "Setting up Bluetooth audio..."
bash $SCRIPT_DIR/config/bluetooth-setup.sh

# Enable and start services
echo "Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable shairport-sync.service
sudo systemctl enable librespot.service
sudo systemctl enable ensure-master-volume.timer

echo "Starting services..."
sudo systemctl restart shairport-sync.service
sudo systemctl restart librespot.service
sudo systemctl start ensure-master-volume.timer

echo ""
echo "====================================================================="
echo "Setup complete! Your Pixie audio middleware is now configured."
echo "====================================================================="
echo ""
echo "You can now stream audio to Pixie using:"
echo "  - AirPlay from iOS/macOS devices"
echo "  - Spotify Connect from any device"
echo "  - Bluetooth from any paired device"
echo ""
echo "To check the status of your audio system, run: /home/pi/bin/audio-status.sh"
echo "To control audio services, run: /home/pi/bin/audio-control.sh"
echo "To manually configure Bluetooth, run: /home/pi/bin/bluetooth-config.sh"
echo ""
echo "Documentation is available in: $SCRIPT_DIR/docs/"
echo ""
echo "Enjoy your music!" 