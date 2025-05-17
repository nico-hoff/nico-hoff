#!/bin/bash

set -e

echo "Setting up PulseAudio middleware architecture for Pixie..."

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIO_DIR="$(dirname "$SCRIPT_DIR")"

# Create necessary directories
mkdir -p /home/pi/bin

# Copy configuration files
echo "Copying configuration files..."
sudo mkdir -p /etc/pulse
sudo cp $AUDIO_DIR/config/system.pa /etc/pulse/system.pa
sudo chmod 644 /etc/pulse/system.pa

# Install helper scripts
echo "Installing helper scripts..."
cp $AUDIO_DIR/scripts/ensure-master-volume.sh /home/pi/bin/
cp $AUDIO_DIR/scripts/audio-status.sh /home/pi/bin/
cp $AUDIO_DIR/scripts/audio-control.sh /home/pi/bin/
chmod +x /home/pi/bin/ensure-master-volume.sh
chmod +x /home/pi/bin/audio-status.sh
chmod +x /home/pi/bin/audio-control.sh

# Install and enable services
echo "Installing systemd services..."
sudo cp $AUDIO_DIR/config/pulseaudio-system.service /etc/systemd/system/
sudo cp $AUDIO_DIR/config/shairport-sync.service /etc/systemd/system/
sudo cp $AUDIO_DIR/config/librespot.service /etc/systemd/system/
sudo cp $AUDIO_DIR/systemd/ensure-master-volume.service /etc/systemd/system/
sudo cp $AUDIO_DIR/systemd/ensure-master-volume.timer /etc/systemd/system/

# Configure shairport-sync
echo "Updating shairport-sync configuration..."
cat > /tmp/shairport-sync.conf.update << EOL
general = {
    name = "Pixie";
    output_backend = "pa";
};

pa = {
    application_name = "Shairport Sync";
    server = "/tmp/pulse-system";
};
EOL
sudo bash -c 'cat /tmp/shairport-sync.conf.update >> /etc/shairport-sync.conf'

# Enable and start services
echo "Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable pulseaudio-system.service
sudo systemctl enable shairport-sync.service
sudo systemctl enable librespot.service
sudo systemctl enable ensure-master-volume.timer

echo "Starting services..."
sudo systemctl start pulseaudio-system.service
sleep 2  # Give PulseAudio time to initialize
sudo systemctl start shairport-sync.service
sudo systemctl start librespot.service
sudo systemctl start ensure-master-volume.timer

echo "Setup complete! Your Pixie audio middleware is now configured."
echo "You can now stream audio via AirPlay or Spotify Connect to 'Pixie'."
echo ""
echo "To check the status of your audio system, run: /home/pi/bin/audio-status.sh"
echo "To control audio services, run: /home/pi/bin/audio-control.sh"
echo ""
echo "Documentation is available in: $AUDIO_DIR/docs/pulseaudio_middleware.md"
echo ""
echo "Enjoy your music!" 