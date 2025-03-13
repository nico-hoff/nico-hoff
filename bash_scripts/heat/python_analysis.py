#!/usr/bin/env python3
import json
import re
from datetime import datetime
import matplotlib.pyplot as plt

def main():
    log_file = "temp_log.json"  # Path to your log file
    timestamps = []
    temperatures = []

    with open(log_file, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # Preprocess the line:
            # Replace the comma in the "temp" value (e.g., "temp": 61,0) with a dot.
            # This regex handles an optional negative sign.
            line_fixed = re.sub(r'("temp":\s*)(-?\d+),(\d+)', r'\1\2.\3', line)
            
            try:
                entry = json.loads(line_fixed)
            except json.JSONDecodeError:
                print(f"Skipping invalid JSON line: {line_fixed}")
                continue

            ts = entry.get("timestamp")
            temp = entry.get("temp")

            if not ts or temp is None:
                continue

            # Parse the ISO 8601 timestamp
            try:
                dt = datetime.fromisoformat(ts)
            except Exception as e:
                print(f"Skipping invalid timestamp '{ts}': {e}")
                continue

            # Convert temperature to float (it should already be fixed by our regex)
            try:
                temp = float(temp)
            except ValueError:
                print(f"Skipping invalid temperature '{temp}'")
                continue

            timestamps.append(dt)
            temperatures.append(temp)

    if not timestamps:
        print("No valid data found in the log.")
        return

    # Sort data by timestamp
    timestamps, temperatures = zip(*sorted(zip(timestamps, temperatures)))

    # Plotting the data
    plt.figure(figsize=(10, 6))
    plt.plot(timestamps, temperatures, linestyle='-')
    plt.xlabel('Time')
    plt.ylabel('Temperature (°C)')
    plt.title('Temperature Over Time')
    plt.grid(True)
    plt.gcf().autofmt_xdate()  # Auto-format x-axis dates

    # Save the figure as a PNG file
    output_file = "temp_plot.png"
    plt.savefig(output_file)
    print(f"Graph saved as {output_file}")

if __name__ == "__main__":
    main()
