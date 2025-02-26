#!/bin/bash
# install_vnc_web.sh
# This script installs TigerVNC, noVNC, and websockify,
# sets up systemd services, and configures automatic startup.

set -e

echo "Updating package list and installing required packages..."
sudo apt update && sudo apt install -y tightvncserver novnc websockify

echo "Creating the VNC user directory..."
mkdir -p ~/.vnc

# echo "Setting up TigerVNC password..."
# vncpasswd

echo "Creating xstartup file..."
cat <<EOL > ~/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startlxde &
EOL
chmod +x ~/.vnc/xstartup

echo "Deploying VNC systemd service..."
sudo cp vncserver.service /etc/systemd/system/vncserver.service

echo "Deploying noVNC systemd service..."
sudo cp novnc.service /etc/systemd/system/novnc.service

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling and starting VNC service..."
sudo systemctl enable vncserver
sudo systemctl start vncserver

echo "Enabling and starting noVNC service..."
sudo systemctl enable novnc
sudo systemctl start novnc

echo "Installation complete."
echo "You can now access your desktop in your browser at: http://$(hostname -I | awk '{print $1}'):6080/vnc.html"