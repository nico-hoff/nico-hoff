#!/bin/bash

LOG_FILE="/tmp/temp_log.txt"
PLOT_SCRIPT="/tmp/temp_plot.gnuplot"

# Create log file
echo "# Time Temperature" > "$LOG_FILE"

# Gnuplot script for real-time plotting
cat <<EOF > "$PLOT_SCRIPT"
set title "Raspberry Pi Temperature Monitor"
set xlabel "Time (seconds)"
set ylabel "Temperature (°C)"
set grid
set term dumb 80 25
set yrange [30:90] # Adjust based on your expected temperature range
plot "$LOG_FILE" using 1:2 with lines title "CPU Temp" lw 2
EOF

clear
echo -e "\e[1;34m🌡️  Raspberry Pi Temperature Monitor 🌡️\e[0m"
echo -e "\e[1;32m----------------------------------------\e[0m"

SECONDS=0  # Track time since start

while true; do
    # Read temperature
    TEMP=$(sensors | awk '/temp/ {print $2}' | tr -d '+°C')

    # Append data to log file
    echo "$SECONDS $TEMP" >> "$LOG_FILE"

    # Display text-based chart
    gnuplot "$PLOT_SCRIPT"

    # Wait before updating
    sleep 2
done