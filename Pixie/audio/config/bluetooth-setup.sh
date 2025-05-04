#!/bin/bash

set -e

echo "Setting up Bluetooth audio for Pixie..."

# Install required packages
echo "Installing Bluetooth packages..."
sudo apt-get update
sudo apt-get install -y bluetooth bluez bluez-tools pulseaudio-module-bluetooth bluez-alsa-utils

# Configure Bluetooth modules for PulseAudio
echo "Configuring PulseAudio Bluetooth modules..."
sudo bash -c 'cat >> /etc/pulse/system.pa' << EOL

### Bluetooth Support
.ifexists module-bluetooth-policy.so
load-module module-bluetooth-policy
.endif

.ifexists module-bluetooth-discover.so
load-module module-bluetooth-discover
.endif
EOL

# Set Bluetooth device class to audio sink and remove PIN authentication
echo "Setting Bluetooth device class to audio sink and configuring auto-pairing..."
sudo bash -c 'cat > /etc/bluetooth/main.conf' << EOL
[General]
Name = Pixie
Class = 0x240414
DiscoverableTimeout = 0
PairableTimeout = 0
AutoEnable=true

[Policy]
AutoEnable=true

[LE]
MinConnectionInterval=7
MaxConnectionInterval=9
ConnectionLatency=0
ConnectionSupervisionTimeout=600
Secure=true

[Security]
# Disable PIN authentication
NoInputNoOutput=true
EOL

# Create specific Bluetooth agent configuration file
echo "Creating Bluetooth agent configuration..."
sudo bash -c 'cat > /etc/bluetooth/input.conf' << EOL
# Allow input devices to be automatically paired
[General]
Automatically=true
EOL

# Add pulse user to bluetooth group
echo "Setting permissions..."
sudo usermod -a -G bluetooth pulse

# Create services for automatically configuring Bluetooth at boot
echo "Creating Bluetooth boot services..."
sudo cp $PWD/bluetooth-boot.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/bluetooth-boot.service

sudo cp $PWD/a2dp-agent.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/a2dp-agent.service

# Install helper script for manual configuration
echo "Installing Bluetooth configuration script..."
sudo cp ../scripts/bluetooth-config.sh /home/pi/bin/
sudo chmod +x /home/pi/bin/bluetooth-config.sh

# Update audio-status.sh script to show Bluetooth connections
echo "Updating audio status script..."
SCRIPT_PATH="/home/pi/bin/audio-status.sh"
if ! grep -q "BLUETOOTH CONNECTIONS" "$SCRIPT_PATH"; then
  cat >> "$SCRIPT_PATH" << EOL

echo -e "\n==== BLUETOOTH CONNECTIONS ===="
bluetoothctl devices | while read -r line; do
    device_id=\$(echo "\$line" | awk '{print \$2}')
    is_connected=\$(bluetoothctl info "\$device_id" | grep "Connected:" | awk '{print \$2}')
    
    if [ "\$is_connected" = "yes" ]; then
        device_name=\$(echo "\$line" | cut -d ' ' -f 3-)
        echo "\$device_name - Connected"
    fi
done
EOL
fi

# Configure the Simple Agent 
echo "Configuring Simple Agent for auto-pairing without PIN..."
sudo bash -c 'cat > /usr/local/bin/simple-agent' << EOL
#!/usr/bin/python3

from gi.repository import GLib
import sys
import dbus
import dbus.service
import dbus.mainloop.glib

AGENT_INTERFACE = "org.bluez.Agent1"
AGENT_PATH = "/test/agent"

class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"

class Agent(dbus.service.Object):
    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Release(self):
        print("Release")

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        print("AuthorizeService (%s, %s)" % (device, uuid))
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        print("RequestPinCode (%s)" % (device))
        return "0000"

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        print("RequestPasskey (%s)" % (device))
        return 0

    @dbus.service.method(AGENT_INTERFACE, in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        print("DisplayPasskey (%s, %06u entered %u)" % (device, passkey, entered))

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        print("DisplayPinCode (%s, %s)" % (device, pincode))

    @dbus.service.method(AGENT_INTERFACE, in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        print("RequestConfirmation (%s, %06d)" % (device, passkey))
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        print("RequestAuthorization (%s)" % (device))
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Cancel(self):
        print("Cancel")

if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SystemBus()
    capability = "NoInputNoOutput"
    
    path = "/test/agent"
    agent = Agent(bus, path)

    obj = bus.get_object("org.bluez", "/org/bluez")
    manager = dbus.Interface(obj, "org.bluez.AgentManager1")
    manager.RegisterAgent(path, capability)
    manager.RequestDefaultAgent(path)

    mainloop = GLib.MainLoop()
    mainloop.run()
EOL
sudo chmod +x /usr/local/bin/simple-agent

# Create a service file for the simple agent
sudo bash -c 'cat > /etc/systemd/system/simple-agent.service' << EOL
[Unit]
Description=Bluetooth Simple Agent
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=simple
ExecStart=/usr/local/bin/simple-agent
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL
sudo chmod 644 /etc/systemd/system/simple-agent.service

# Enable and restart services
echo "Enabling and restarting services..."
sudo systemctl daemon-reload
sudo systemctl enable bluetooth-boot.service
sudo systemctl enable a2dp-agent.service
sudo systemctl enable simple-agent.service
sudo systemctl restart bluetooth

# Configure Bluetooth now
echo "Configuring Bluetooth now..."
sudo bluetoothctl power on
sudo bluetoothctl discoverable on
sudo bluetoothctl pairable on
sudo bluetoothctl agent NoInputNoOutput
sudo bluetoothctl default-agent

# Set device class to audio sink
sudo hciconfig hci0 class 0x240414
sudo hciconfig hci0 name Pixie

# Restart PulseAudio to load Bluetooth modules
sudo -u pulse pactl load-module module-bluetooth-policy
sudo -u pulse pactl load-module module-bluetooth-discover

# Start the agent services
sudo systemctl start a2dp-agent.service
sudo systemctl start bluetooth-boot.service
sudo systemctl start simple-agent.service

echo "Bluetooth audio setup complete!"
echo "Your Raspberry Pi is now discoverable as 'Pixie' and will allow pairing without PIN authentication."
echo "To pair a device, search for 'Pixie' on your Bluetooth device and connect."
echo ""
echo "To check Bluetooth status, run: /home/pi/bin/audio-status.sh"
echo "To manually configure Bluetooth, run: /home/pi/bin/bluetooth-config.sh"
echo ""
echo "Pixie will be automatically available as a Bluetooth speaker on boot." 