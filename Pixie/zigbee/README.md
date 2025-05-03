# Install Zigbee etc.


## 1. Install prerequisites: Open a terminal and run the following commands to update your system and install necessary packages:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install git curl -y
```

## 2. Install Node.js: Zigbee2mqtt requires Node.js. Install it using the following commands:
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

Update Node
```bash
sudo npm cache clean -f
sudo npm install -g n
sudo n stable
```

## 3. Install Zigbee2mqtt: Clone the Zigbee2mqtt repository and install it:
```bash
sudo git clone https://github.com/Koenkk/zigbee2mqtt.git /opt/zigbee2mqtt
cd /opt/zigbee2mqtt
sudo npm install

# Only if already installed
npm ci 
```

```bash
sudo npm install -g pnpm
cd /opt/zigbee2mqtt
sudo pnpm install
sudo pnpm run build
```

## 4. Configure Zigbee2mqtt: Create a configuration file:

Add this to your config.txt as `/boot/config.txt` or `/boot/firmware/config.txt` (Ubuntu) to enable serial detection.

```bash
enable_uart=1
dtoverlay=pi3-miniuart-bt
```

Add the following configuration, replacing YOUR_SERIAL_PORT with the serial port of your module (usually /dev/ttyAMA0):
```bash
sudo nano /opt/zigbee2mqtt/data/configuration.yaml
```

If unkown do this and look for enabled

```bash
sudo dmesg | grep tty
```

>[    1.514346] fe201000.serial: ttyAMA0 at MMIO 0xfe201000 (irq = 37, base_baud = 0) is a PL011 rev2
>
>[    1.514969] printk: legacy console [ttyAMA0] enabled

and check with 

```bash
ls /dev/tty*
```

```bash
homeassistant: false
permit_join: true
mqtt:
  base_topic: zigbee2mqtt
  server: 'mqtt://localhost'
serial:
  adapter: ADAPTER
  port: YOUR_SERIAL_PORT
```

Use minicom to test the serial port: Install minicom and use it to test the serial port:

```bash
sudo apt install minicom
sudo minicom -D /dev/ttyAMA0
```


```bash
sudo apt install -y mosquitto mosquitto-clients
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
```

```bash
sudo cp zigbee2mqtt.service /etc/systemd/system/zigbee2mqtt.service
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable zigbee2mqtt
sudo systemctl start zigbee2mqtt
```

```bash
sudo journalctl -u zigbee2mqtt -f
```

```bash
mosquitto_pub -t 'zigbee2mqtt/bridge/request/permit_join' -m 'true'
```

## Abort

HomeMatic is not compatible with Zigbee

### Error Logging

```bash
z2m: Error while starting zigbee-herdsman
Mär 14 09:52:02 sushijumper npm[6978]: [2025-03-14 09:52:02] error:         z2m: Failed to start zigbee-herdsman
Mär 14 09:52:02 sushijumper npm[6978]: [2025-03-14 09:52:02] error:         z2m: Check https://www.zigbee2mqtt.io/guide/installation/20_zigbee2mqtt-fails-to-start_crashes-runtime.html for possible solutions
Mär 14 09:52:02 sushijumper npm[6978]: [2025-03-14 09:52:02] error:         z2m: Exiting...
Mär 14 09:52:02 sushijumper npm[6978]: [2025-03-14 09:52:02] error:         z2m: Error: Failed to connect to the adapter (Error: SRSP - SYS - ping after 6000ms)
```