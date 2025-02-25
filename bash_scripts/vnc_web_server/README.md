# VNC Web Installation Script

## Setup

### Installer (recommended)

#### Make the script executable:

```bash
chmod +x install_vnc_web.sh
```

#### Run the script:

```bash
./install_vnc_web.sh
```

## How to Access Your Desktop

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

## Additional Notes

The VNC password will be set during installation.
The script ensures automatic startup on boot.

### To stop the VNC service:
```bash
sudo systemctl stop vncserver
sudo systemctl stop novnc
```
### To restart the services:
```bash
sudo systemctl restart vncserver
sudo systemctl restart novnc
```

🚀