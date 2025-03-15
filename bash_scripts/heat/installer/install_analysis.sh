#!/bin/bash

# Get the current working directory
cwd=$(pwd)
venv_path="$cwd/venv"
requirements_path="$cwd/requirements.txt"
run_analysis_path="$cwd/bash_scripts/heat/run_analysis.sh"
python_analysis_path="$cwd/bash_scripts/heat/python_analysis.py"

echo "Checking for virtual environment..."
if [ ! -d "$venv_path" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$venv_path"
fi

echo "Installing required packages..."
source "$venv_path/bin/activate"
# pip3 install -r "$requirements_path"
deactivate

echo "Creating analysis wrapper script..."
cat <<EOL > "$run_analysis_path"
#!/bin/bash
source "$venv_path/bin/activate"
python3 "$python_analysis_path"
deactivate
EOL

echo "Making wrapper script executable..."
chmod +x "$run_analysis_path"

echo "Setting up hourly cron job..."
(crontab -l 2>/dev/null; echo "0 * * * * $run_analysis_path") | sort - | uniq - | crontab -

echo "Installation complete. Analysis will run every hour."