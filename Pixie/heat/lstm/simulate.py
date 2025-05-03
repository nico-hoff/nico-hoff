# /home/pi/Desktop/nico-hoff/generate_future_data.py
import csv
from datetime import datetime, timedelta
import random

def generate_full_load(duration_minutes):
    data = []
    current_time = datetime.now()
    
    for i in range(duration_minutes * 60):  # One entry per second
        timestamp = current_time + timedelta(seconds=i)
        # Full load with small variations
        mhz = random.uniform(1750, 1800)
        data.append([timestamp.strftime('%Y-%m-%d %H:%M:%S'), f'{mhz:.2f}'])
    
    return data

def generate_idle(duration_minutes):
    data = []
    current_time = datetime.now()
    
    for i in range(duration_minutes * 60):
        timestamp = current_time + timedelta(seconds=i)
        # Idle state with small variations
        mhz = random.uniform(1450, 1500)
        data.append([timestamp.strftime('%Y-%m-%d %H:%M:%S'), f'{mhz:.2f}'])
    
    return data

def generate_dynamic(duration_minutes):
    data = []
    current_time = datetime.now()
    
    for i in range(duration_minutes * 60):
        timestamp = current_time + timedelta(seconds=i)
        # Create a dynamic pattern
        base = 1500 + 300 * abs(((i % 300) - 150) / 150)  # 5-minute cycle
        variation = random.uniform(-50, 50)
        mhz = base + variation
        data.append([timestamp.strftime('%Y-%m-%d %H:%M:%S'), f'{mhz:.2f}'])
    
    return data

def main():
    # Generate 10 minutes of each pattern
    full_load_data = generate_full_load(10)
    idle_data = generate_idle(10)
    dynamic_data = generate_dynamic(10)
    
    # Combine all data
    all_data = full_load_data + idle_data + dynamic_data
    
    # Write to CSV file
    with open('../data/tests/future.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['timestamp', 'mhz'])  # Header
        writer.writerows(all_data)

if __name__ == "__main__":
    main()