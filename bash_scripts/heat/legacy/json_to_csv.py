#!/usr/bin/env python3
import json
import re
import csv
from datetime import datetime

def main():
    log_file = "data/temp_log.json"  # Path to your log file
    csv_file = "data/temp_log.csv"   # Path to your output CSV file

    with open(log_file, "r") as f, open(csv_file, "w", newline='') as csvfile:
        fieldnames = ['timestamp', 'temp']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

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

            writer.writerow({'timestamp': dt.isoformat(), 'temp': temp})

    print(f"CSV file saved as {csv_file}")

if __name__ == "__main__":
    main()