#!/bin/bash

# Script to configure Bluetooth for Pixie
echo "Configuring Bluetooth for Pixie..."

# Set Bluetooth to power on and be discoverable
echo "Setting Bluetooth to be discoverable and pairable..."
sudo bluetoothctl power on
sudo bluetoothctl discoverable on
sudo bluetoothctl pairable on
sudo bluetoothctl agent NoInputNoOutput
sudo bluetoothctl default-agent

# Set device class to audio sink (0x240414 = Audio sink)
echo "Setting device class to audio sink..."
sudo hciconfig hci0 class 0x240414

# Set the device name to Pixie
echo "Setting device name to Pixie..."
sudo hciconfig hci0 name Pixie

# Restart the Bluetooth service
echo "Restarting Bluetooth service..."
sudo systemctl restart bluetooth
sudo systemctl restart bluetooth-boot.service
sudo systemctl restart a2dp-agent.service
sudo systemctl restart simple-agent.service

echo "Bluetooth configuration complete."
echo "Pixie should now be visible as a Bluetooth speaker and allow pairing without PIN."
echo "You can pair and connect from your devices now." 