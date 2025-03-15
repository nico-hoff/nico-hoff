#!/bin/bash

echo "Checking for virtual environment..."
if [ ! -d "/home/pi/Desktop/nico-hoff/venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv /home/pi/Desktop/nico-hoff/venv
fi

echo "Installing required packages..."
source /home/pi/Desktop/nico-hoff/venv/bin/activate
# pip3 install -r /home/pi/Desktop/nico-hoff/requirements.txt
deactivate

echo "Creating analysis wrapper script..."
cat <<EOL > /home/pi/Desktop/nico-hoff/bash_scripts/heat/run_analysis.sh
#!/bin/bash
source /home/pi/Desktop/nico-hoff/venv/bin/activate
python3 /home/pi/Desktop/nico-hoff/bash_scripts/heat/python_analysis.py
deactivate
EOL

echo "Making wrapper script executable..."
chmod +x /home/pi/Desktop/nico-hoff/bash_scripts/heat/run_analysis.sh

echo "Setting up hourly cron job..."
(crontab -l 2>/dev/null; echo "0 * * * * /home/pi/Desktop/nico-hoff/bash_scripts/heat/run_analysis.sh") | sort - | uniq - | crontab -

echo "Installation complete. Analysis will run every hour."
