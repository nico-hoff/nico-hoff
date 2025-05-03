# VNC Web Installation Script

## Table of Contents
- [Installation](#installation)
- [Accessing Your Desktop](#accessing-your-desktop)
- [Service Setup Explanation](#service-setup-explanation)
- [Additional Commands](#additional-commands)

## Installation

### Installer (recommended)

1. Make the script executable:

   ```bash
   chmod +x install_vnc_web.sh
   ```

2. Run the script:

   ```bash
   ./install_vnc_web.sh
   ```

## Accessing Your Desktop

Once the script completes, open any browser on the same network and go to:

```bash
http://kali.local:6080/vnc.html
```
or
```bash
http://<your-kali-ip>:6080/vnc.html
```

You can find your Kali IP with:

```bash
hostname -I
```

## Service Setup Explanation

This section explains the noVNC/x11vnc setup, clarifying IP bindings and how websockify operates.

### Overview

- **x11vnc**: Provides VNC access to your X display (desktop).
- **websockify (with noVNC)**: Converts WebSocket connections from your browser into VNC protocol messages.

Both services are managed using systemd service files.

### Service Files and Key Commands

**x11vnc Service (x11vnc.service):**

```bash
/usr/bin/x11vnc -display :0 -forever -rfbport 5900 --listen 0.0.0.0 -shared -nopw -auth guess -xkb
```
- *-rfbport 5900*: x11vnc listens on port 5900.
- *--listen 0.0.0.0*: Listens on all interfaces.

**noVNC / websockify Service (novnc.service):**

```bash
/usr/bin/websockify --verbose --web /usr/share/novnc/ 6080 REPLACE_IP:5900
```
- *6080*: Port for websockify and noVNC web interface.
- *REPLACE_IP*: Replaced with 127.0.0.1 during installation to specify the internal VNC target.

### How the Connection Works

1. The browser connects to websockify at `http://yourhostname:6080/vnc.html`.
2. websockify (bound to 0.0.0.0) serves the noVNC web interface.
3. After loading, websockify forwards the connection to x11vnc via `127.0.0.1:5900`.

#### Clarification: 0.0.0.0 vs. 127.0.0.1

- **0.0.0.0**: Binds a service to all available network interfaces.
- **127.0.0.1**: Specifies the local loopback interface, used as the target for VNC traffic.

## Additional Commands

### To Stop the VNC Service:
```bash
sudo systemctl stop vncserver
sudo systemctl stop novnc
```

### To Restart the Services:
```bash
sudo systemctl restart vncserver
sudo systemctl restart novnc
```

🚀