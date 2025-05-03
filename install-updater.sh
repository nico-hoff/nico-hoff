#!/bin/bash

# Define script path
SCRIPT_PATH="/usr/local/bin/update-all.sh"

echo "Installing update script..."

# Create the update script
cat << 'EOF' | sudo tee $SCRIPT_PATH > /dev/null
#!/bin/bash

echo "Starting system update..."

# Update package list
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y

# Perform full upgrade (handles dependencies)
sudo apt full-upgrade -y

# Remove unused packages
sudo apt autoremove -y

# Clean up package cache
sudo apt clean

echo "System update completed successfully!"
EOF

# Make the script executable
sudo chmod +x $SCRIPT_PATH

echo "Update script installed at $SCRIPT_PATH"

# Ask user if they want to enable automatic updates via cron
read -p "Do you want to enable automatic daily updates at 3 AM? (y/n): " ENABLE_CRON

if [[ "$ENABLE_CRON" == "y" || "$ENABLE_CRON" == "Y" ]]; then
    # Add cron job
    (crontab -l 2>/dev/null; echo "0 3 * * * $SCRIPT_PATH") | crontab -
    echo "Automatic updates scheduled at 3 AM daily."
else
    echo "Automatic updates not enabled. You can run 'update-all.sh' manually."
fi

echo "Installation complete!"
