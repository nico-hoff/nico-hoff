#!/bin/bash

# Ensure the script stops if any command fails
set -e

# Set the username dynamically
USER=${USER:-$(whoami)}

# Activate the virtual environment
source "/home/$USER/Desktop/nico-hoff/venv/bin/activate"

# Run the Python script
python3 "/home/$USER/Desktop/nico-hoff/bash_scripts/heat/python_analysis.py" -f

# Deactivate the virtual environment (only if inside a venv)
deactivate || true
