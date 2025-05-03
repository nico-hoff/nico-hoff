# WiFi Access Point

This script sets up a WiFi access point on a Raspberry Pi (Kali OS) using a virtual AP interface (ap0) created from wlan0, and configures hostapd, dnsmasq (for DHCP), and NAT via iptables.

[The Script](setup_wifi_ap.sh)

## WiFi Configuration

See the first lines of the bash script.

## Setup

### Installer (recommended)

To install and setup the access point fully automaticlly use [this script](installer.sh)
```bash
chmod +x installer.sh
sudo ./installer.sh
```

### Manuel

Copy or write [this script](setup_wifi_ap.sh) to this location:

```bash
sudo cp setup_wifi_ap.sh /usr/local/bin/setup_wifi_ap.sh
```
or 
```bash
sudo nano /usr/local/bin/setup_wifi_ap.sh
```

Make it executable:
```bash
chmod +x /usr/local/bin/setup_wifi_ap.sh
```

## Setup Systemd Service File

Create a service unit file with the following content to run the script on boot by copying or writing [this script](setup_wifi_ap.service) to this location:

```bash
sudo cp setup_wifi_ap.service /etc/systemd/system/setup_wifi_ap.service
```
or 
```bash
sudo nano /etc/systemd/system/setup_wifi_ap.service
```

## Deploy the servive

1. Reload systemd to register the new serivce:
```bash
sudo systemctl daemon-reload
````
2. Enable the service to run on boot:
```bash
sudo systemctl enable setup_wifi_ap.service
```
3. Start the service:
```bash
sudo systemctl start setup_wifi_ap.service
```