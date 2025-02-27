#!/bin/bash

while true; do
    clear
    echo -e "\e[1;34m🌡️  Raspberry Pi Temperature Monitor 🌡️\e[0m"
    echo -e "\e[1;32m----------------------------------------\e[0m"

    # Read the temperature
    sensors | awk '
    /temp/ {
        temp=$2;
        gsub(/\+/,"",temp);
        gsub(/°C/,"",temp);
        color="\033[1;32m"; # Green
        if (temp+0 >= 50) color="\033[1;33m"; # Yellow
        if (temp+0 >= 70) color="\033[1;31m"; # Red
        printf "%s🌡️  %s°C\033[0m\n", color, temp;
    }'

    echo -e "\e[1;32m----------------------------------------\e[0m"
    
    sleep 1
done