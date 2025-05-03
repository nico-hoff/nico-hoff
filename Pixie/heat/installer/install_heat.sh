
sudo apt update
sudo apt install lm-sensors -y
sudo apt install sysstat -y
sudo apt install -y gnuplot

sudo sensors-detect

# montor_head.sh
# sudo nano /boot/config.txt
# sudo nano /boot/firmware/config.txt

# dtoverlay=gpio-fan,gpiopin=14,temp=55000