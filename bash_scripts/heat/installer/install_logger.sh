#!/bin/bash

# Get the current working directory
cwd=$(pwd)
relativ_path="temp_logger.sh"

ExecStart="$cwd/$relativ_path"

cwd=$(pwd)
LOGFILE="$cwd/data/raw/temp_log_multi.csv"

echo "Logging to: $LOGFILE"

# Get the current user
current_user=$(whoami)

# Create a systemd service file for temp_logger
cat <<EOL | sudo tee /etc/systemd/system/temp_logger.service
[Unit]
Description=Temperature Logger Service
After=network.target

[Service]
ExecStart=$ExecStart
Restart=always
User=$current_user

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable temp_logger.service

# Start the service immediately
sudo systemctl start temp_logger.service

echo "\ntemp_logger service has been added and started.\n"

# Watch the logs of the temp_logger service
sudo journalctl -u temp_logger.service -f