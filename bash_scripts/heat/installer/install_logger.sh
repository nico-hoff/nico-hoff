#!/bin/bash

# Create a systemd service file for temp_logger
cat <<EOL | sudo tee /etc/systemd/system/temp_logger.service
[Unit]
Description=Temperature Logger Service
After=network.target

[Service]
ExecStart=/home/pi/Desktop/nico-hoff/bash_scripts/heat/temp_logger.sh
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable temp_logger.service

# Start the service immediately
sudo systemctl start temp_logger.service

echo "temp_logger service has been added and started."