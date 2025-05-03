#!/bin/bash

# Script to change the hostname globally on a Raspberry Pi running Ubuntu
# Usage: ./change_hostname.sh new_hostname

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    echo "Please use: sudo $0 $*" >&2
    exit 1
fi

# Check if a hostname was provided
if [ -z "$1" ]; then
    echo "Error: No hostname specified"
    echo "Usage: $0 <new_hostname>"
    exit 1
fi

NEW_HOSTNAME="$1"
CURRENT_HOSTNAME=$(hostname)

echo "Changing hostname from $CURRENT_HOSTNAME to $NEW_HOSTNAME..."

# Update /etc/hostname
echo "$NEW_HOSTNAME" > /etc/hostname

# Update /etc/hosts
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# Set the hostname for the current session
hostnamectl set-hostname "$NEW_HOSTNAME"

# Update Avahi/mDNS if installed
if command -v avahi-daemon &> /dev/null; then
    systemctl restart avahi-daemon
fi

# Update any Bluetooth name if present
if command -v bluetoothctl &> /dev/null; then
    bluetoothctl system-alias "$NEW_HOSTNAME"
fi

# If using NetworkManager, this updates the DHCP hostname
if command -v nmcli &> /dev/null; then
    nmcli general hostname "$NEW_HOSTNAME"
fi

echo "Hostname has been changed to $NEW_HOSTNAME"
echo "Please reboot the system for all changes to take effect: sudo reboot"

exit 0 