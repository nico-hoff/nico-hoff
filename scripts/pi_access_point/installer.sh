#!/bin/bash
# installer.sh
# This script installs necessary packages, copies the WiFi Access Point setup script 
# and the systemd service file into their proper locations, and configures the service
# to run on boot.

set -e

echo "Updating package list and installing required packages..."
sudo apt update && sudo apt install -y hostapd dnsmasq iptables-persistent iw

echo "Deploying setup script..."
sudo cp setup_wifi_ap.sh /usr/local/bin/setup_wifi_ap.sh
sudo chmod +x /usr/local/bin/setup_wifi_ap.sh

echo "Deploying systemd service file..."
sudo cp setup_wifi_ap.service /etc/systemd/system/setup_wifi_ap.service

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling the WiFi AP service to run on boot..."
sudo systemctl enable setup_wifi_ap.service

echo "Starting the WiFi AP service..."
sudo systemctl start setup_wifi_ap.service

echo "Installation complete. Your WiFi Access Point will be configured on boot."