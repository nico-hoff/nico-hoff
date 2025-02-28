#!/bin/bash
# install_vnc_web.sh
# This script installs x11vnc, noVNC, and websockify,
# sets up systemd services, and configures automatic startup.

set -e

echo "Checking for required packages..."
MISSING_PKGS=""

# Check for missing packages
for pkg in x11vnc novnc websockify; do
    dpkg -s "$pkg" >/dev/null 2>&1 || MISSING_PKGS="$MISSING_PKGS $pkg"
done

# Install if missing
if [ -n "$MISSING_PKGS" ]; then
    echo "The following packages are missing:$MISSING_PKGS"
    echo "Do you want to install them? (y/n) "
    read user_response
    if [ "$user_response" = "y" ]; then
        echo "Updating package list and installing:$MISSING_PKGS"
        sudo apt update && sudo apt install -y $MISSING_PKGS
    else
        echo "Skipping package installation."
    fi
else
    echo "✅ All required packages are already installed."
fi

# Get the username and home directory of the person running the script
INSTALL_USER=$(whoami)
INSTALL_HOME=$(eval echo ~$INSTALL_USER)
INSTALL_IP=$(hostname -I | awk '{print $1}')

echo "Detected user: $INSTALL_USER"
echo "Detected home directory: $INSTALL_HOME"


echo "Setting up VNC and noVNC services..."
# Modify and copy x11vnc.service
echo "Deploying x11vnc.service..."
sudo cp x11vnc.service /etc/systemd/system/

# Modify and copy novnc.service
echo "Copying and modifying novnc.service..."
sed -e "s|REPLACE_IP|${INSTALL_IP}|g" \
    novnc.service | sudo tee /etc/systemd/system/novnc.service > /dev/null

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Restarting and enabling x11vnc service..."
sudo systemctl enable --now x11vnc
sudo systemctl restart x11vnc

echo "Restarting and enabling noVNC service..."
sudo systemctl enable --now novnc
sudo systemctl restart novnc

echo "Restaring and enabling hostname dns serivce..."
sudo systemctl start avahi-daemon
sudo systemctl enable avahi-daemon

# Add VNC access message to ~/.zshrc
VNC_MSG="echo \"You can access the desktop in your browser at: http://\$(hostname):6080/vnc.html\""

if ! grep -Fxq "$VNC_MSG" "$INSTALL_HOME/.zshrc"; then
    echo "Adding VNC access message to ~/.zshrc..."
    echo "$VNC_MSG" >> "$INSTALL_HOME/.zshrc"
else
    echo "VNC message already exists in ~/.zshrc"
fi

# Ensure correct ownership in case script is run with sudo
sudo chown "$(whoami)":"$(whoami)" "$INSTALL_HOME/.zshrc"

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
eval $VNC_MSG