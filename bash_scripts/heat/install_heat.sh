
sudo apt update
sudo apt install lm-sensors -y

sudo sensors-detect

# sudo nano /boot/config.txt
# sudo nano /boot/firmware/config.txt

# dtoverlay=gpio-fan,gpiopin=14,temp=55000