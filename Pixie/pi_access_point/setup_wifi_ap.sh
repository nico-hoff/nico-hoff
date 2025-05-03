#!/bin/bash
# /usr/local/bin/setup_wifi_ap.sh
# This script sets up a WiFi access point on a Raspberry Pi (Kali OS)
# using a virtual AP interface (ap0) created from wlan0, and configures hostapd,
# dnsmasq (for DHCP), and NAT via iptables.
#
# Customize these variables as needed:
AP_INTERFACE="ap0"
UNDERLYING_IF="wlan0"
AP_IP="192.168.50.1"
SSID="pi"
HIDE_SSID="0"
WPA_PASS="87654312"
CHANNEL="6"
DHCP_RANGE_START="192.168.50.10"
DHCP_RANGE_END="192.168.50.100"
LEASE_TIME="12h"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

echo "Creating AP interface ${AP_INTERFACE} from ${UNDERLYING_IF}..."
/sbin/iw dev "${UNDERLYING_IF}" interface add "${AP_INTERFACE}" type __ap

echo "Bringing up ${AP_INTERFACE} and assigning IP ${AP_IP}..."
ip link set "${AP_INTERFACE}" up
ip addr flush dev "${AP_INTERFACE}"
ip addr add "${AP_IP}/24" dev "${AP_INTERFACE}"

echo "Writing hostapd configuration..."
cat << EOF > /etc/hostapd/hostapd.conf
interface=${AP_INTERFACE}
driver=nl80211
ssid=${SSID}
hw_mode=g
channel=${CHANNEL}
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=${HIDE_SSID}   # Hide SSID
wpa=2
wpa_passphrase=${WPA_PASS}
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

# Ensure hostapd is pointed to our config (if the file exists)
if [ -f /etc/default/hostapd ]; then
  sed -i 's|^#\?DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
fi

echo "Writing dnsmasq configuration..."
cat << EOF > /etc/dnsmasq.conf
interface=${AP_INTERFACE}
dhcp-range=${DHCP_RANGE_START},${DHCP_RANGE_END},${LEASE_TIME}
EOF

echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

echo "Setting up NAT iptables rules..."
iptables -t nat -A POSTROUTING -o "${UNDERLYING_IF}" -j MASQUERADE
iptables -A FORWARD -i "${UNDERLYING_IF}" -o "${AP_INTERFACE}" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "${AP_INTERFACE}" -o "${UNDERLYING_IF}" -j ACCEPT

echo "Installing iptables-persistent (if not already installed) and saving rules..."
apt-get update && apt-get install -y iptables-persistent
netfilter-persistent save

echo "Restarting hostapd and dnsmasq..."
systemctl restart hostapd
systemctl restart dnsmasq

echo "WiFi Access Point configured on interface ${AP_INTERFACE} with hidden SSID '${SSID}'."