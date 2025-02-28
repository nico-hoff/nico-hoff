#!/bin/bash

set -e

sudo apt update
sudo apt install python3-venv

python3 -m venv venv
echo
echo "Sleep 3 sec before sourcing the venv"
sleep 3
source venv/bin/activate
echo "installing python3 dependencies from requirements.txt"
pip install -r requirements.txt
