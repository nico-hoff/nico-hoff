import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from tqdm import tqdm
import os
import argparse

# Add argument parsing
parser = argparse.ArgumentParser(description='Temperature analysis script')
parser.add_argument('-f', '--full', action='store_true', help='Run analysis for all time windows')
args = parser.parse_args()

# Load the data
print("\nLoading data...")
df = pd.read_csv('data/raw/temp_log_multi.csv', parse_dates=['timestamp'])

# Boxplot for temperature and MHz distribution
print("Plotting distributions...")
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
sns.boxplot(y=df['temp'], ax=ax1)
ax1.set_title('Temperature Distribution')
ax1.set_ylabel('Temperature')
ax1.grid(True, axis='y', linestyle='--', alpha=0.7)

sns.boxplot(y=df['avg_mhz'], ax=ax2)
ax2.set_title('CPU Frequency Distribution')
ax2.set_ylabel('MHz')
ax2.grid(True, axis='y', linestyle='--', alpha=0.7)

plt.tight_layout()
plt.savefig(f'graphs/boxplot_total.png')
plt.show()

# Defining helper function for saving the last x minutes of data
def plot_time_window(i, df, minutes, title_suffix, window_size):
    # Calculate rolling statistics for temperature
    df['mhz_rolling_avg'] = df['avg_mhz'].rolling(window=window_size).mean()
    df['rolling_avg'] = df['temp'].rolling(window=window_size).mean()
    df['rolling_std'] = df['temp'].rolling(window=window_size).std()
    df['bollinger_upper'] = df['rolling_avg'] + (3 * df['rolling_std'])
    df['bollinger_lower'] = df['rolling_avg'] - (3 * df['rolling_std'])

    window_df = df[df['timestamp'] >= df['timestamp'].max() - timedelta(minutes=minutes)]
    if len(window_df) == 0:
        return

    window_df = window_df.dropna()

    # Create figure with two subplots
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

    # Temperature plot
    sns.lineplot(x=window_df['timestamp'], y=window_df['temp'], 
                color='black', linestyle='-', label='Temperature', alpha=0.1, ax=ax1, linewidth=2)
    sns.lineplot(x=window_df['timestamp'], y=window_df['rolling_avg'], 
                color='orange', label=f'Rolling Avg (window={window_size})', ax=ax1, linewidth=2.5)
    ax1.fill_between(window_df['timestamp'], 
                    window_df['bollinger_lower'], 
                    window_df['bollinger_upper'],
                    color='grey', alpha=0.3, label=f'Bollinger Bands (±3σ, window={window_size})')
    ax1.set_title(f'Temperature Plot - Last {title_suffix}')
    ax1.set_ylabel('Temperature')
    ax1.grid(True)
    ax1.legend()

    # MHz plot
    sns.lineplot(x=window_df['timestamp'], y=window_df['avg_mhz'], 
                color='blue', label='CPU Frequency', alpha=0.1, ax=ax2, linewidth=2)
    sns.lineplot(x=window_df['timestamp'], y=window_df['mhz_rolling_avg'], 
                color='blue', label='Avg CPU Frequency', ax=ax2, linewidth=2.5)
    ax2.set_title(f'CPU Frequency - Last {title_suffix}')
    ax2.set_xlabel('Timestamp')
    ax2.set_ylabel('MHz')
    ax2.grid(True)
    ax2.legend()

    plt.xticks(rotation=45)
    plt.tight_layout()
    
    save_path = f'graphs/plot_{i}_{title_suffix}.png'
    plt.savefig(save_path)
    plt.show()

# Time windows mapping - structured as proper dictionary
time_windows = {
    '10_min': {'minutes': 10, 'window_size': 20},    # 20 seconds
    '30_min': {'minutes': 30, 'window_size': 60},    # 1 minute
    '4_h': {'minutes': 240, 'window_size': 300},     # 5 minutes
    '1_d': {'minutes': 1440, 'window_size': 3600},     # 1 hour
    '1_w': {'minutes': 10080, 'window_size': 14400}   # 4 hours
}

# Plot different time windows
print("Plotting temperature time windows...")
if args.full:
    windows_to_plot = time_windows
else:
    # Only use first two time windows if -f is not set
    windows_to_plot = dict(list(time_windows.items())[:2])

for i, (window_name, settings) in enumerate(tqdm(windows_to_plot.items(), desc="Rendering Time Windows")):
    plot_time_window(
        i,
        df,
        minutes=settings['minutes'],
        title_suffix=window_name,
        window_size=settings['window_size']
    )

# Filter the dataframe for rows where the timestamp is equal to today
today = datetime.now().date()
yesterday = today - timedelta(days=1)
df = df[(df['timestamp'].dt.date >= today)] #  - timedelta(days=1))]
