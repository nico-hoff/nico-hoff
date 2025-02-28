#!/bin/bash
# install_vnc_web.sh
# This script installs x11vnc, noVNC, and websockify,
# sets up systemd services, and configures automatic startup.

set -e

echo "Checking for required packages..."
# if ! dpkg -l | grep -qE 'x11vnc|novnc|websockify'; then
read -p "Required packages are missing. Do you want to install x11vnc, novnc, and websockify? (y/n) " -n 1 -r user_response
echo

if [[ $user_response == "y" ]]; then
    echo "Updating package list and installing required packages..."
    sudo apt update && sudo apt install -y x11vnc novnc websockify
else 
    echo "Skipping package installation. Exiting..."
    exit 1
fi
# else
#     echo "All required packages are already installed."
# fi

# Get the username and home directory of the person running the script
# INSTALL_USER=$(whoami)
INSTALL_USER=root
INSTALL_HOME=$(eval echo ~$INSTALL_USER)
INSTALL_IP=$(hostname -I | awk '{print $1}')

echo "Detected user: $INSTALL_USER"
echo "Detected home directory: $INSTALL_HOME"


echo "Setting up VNC and noVNC services..."

# Modify and copy x11vnc.service
echo "Copying and modifying x11vnc.service..."
sed -e "s|^User=.*|User=$INSTALL_USER|" \
    -e "s|^WorkingDirectory=.*|WorkingDirectory=$INSTALL_HOME|" \
    -e "s|/home/pi|$INSTALL_HOME|g" x11vnc.service | sudo tee /etc/systemd/system/x11vnc.service > /dev/null

# Modify and copy novnc.service
echo "Copying and modifying novnc.service..."
sed -e "s|REPLACE_IP|${INSTALL_IP}|g" \
    -e "s|REPLACE_ME|${INSTALL_USER}|g" \
    novnc.service | sudo tee /etc/systemd/system/novnc.service > /dev/null

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Restarting and enabling x11vnc service..."
sudo systemctl enable --now x11vnc
sudo systemctl restart x11vnc

echo "Restarting and enabling noVNC service..."
sudo systemctl enable --now novnc
sudo systemctl restart novnc

# Add VNC access message to ~/.zshrc
VNC_MSG="echo \"You can now access your desktop in your browser at: http://\$(hostname -I | awk '{print \$1}'):6080/vnc.html\""

if ! grep -Fxq "$VNC_MSG" "$INSTALL_HOME/.zshrc"; then
    echo "Adding VNC access message to ~/.zshrc..."
    echo "$VNC_MSG" >> "$INSTALL_HOME/.zshrc"
else
    echo "VNC message already exists in ~/.zshrc"
fi

# Ensure correct ownership in case script is run with sudo
sudo chown "$INSTALL_USER":"$INSTALL_USER" "$INSTALL_HOME/.zshrc"

# Confirm that services are running
echo "Checking service status..."
if systemctl is-active --quiet x11vnc; then
    echo "✔ x11vnc is running."
else
    echo "❌ x11vnc failed to start. Check logs with: sudo journalctl -u x11vnc --no-pager"
fi

if systemctl is-active --quiet novnc; then
    echo "✔ noVNC is running."
else
    echo "❌ noVNC failed to start. Check logs with: sudo journalctl -u novnc --no-pager"
fi

echo "Installation complete."
echo "You can now access your desktop in your browser at: http://$(hostname -I | awk '{print $1}'):6080/vnc.html"