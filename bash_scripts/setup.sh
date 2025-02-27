# Install gh
curl -sS https://webi.sh/gh | sh	

# edit config.txt
sudo sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' /boot/config.txt
sudo sed -i 's/#hdmi_group=1/hdmi_group=1/g' /boot/config.txt
sudo sed -i 's/#hdmi_mode=1/hdmi_mode=4/g' /boot/config.txt

