import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from tqdm import tqdm
import os

# Load the data
print("\nLoading data...")
df = pd.read_csv('data/raw/temp_log.csv', parse_dates=['timestamp'])

# Boxplot for temperature distribution
print("Plotting temperature distribution...")
plt.figure(figsize=(6, 4))
sns.boxplot(y=df['temp'])
plt.title('Temperature Distribution')
plt.ylabel('Temperature')
plt.grid(True, axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig(f'graphs/boxplot_total.png')
plt.show()

# Defining helper function for saving the last x minutes of data
def plot_time_window(i, df, minutes, title_suffix, window_size):

    # Calculate rolling statistics
    df['rolling_avg'] = df['temp'].rolling(window=window_size).mean()
    df['rolling_std'] = df['temp'].rolling(window=window_size).std()
    df['bollinger_upper'] = df['rolling_avg'] + (3 * df['rolling_std'])
    df['bollinger_lower'] = df['rolling_avg'] - (3 * df['rolling_std'])

    window_df = df[df['timestamp'] >= df['timestamp'].max() - timedelta(minutes=minutes)]
    if len(window_df) == 0:
        return

    window_df = window_df.dropna()  # Drop NaN values before plotting

    plt.figure(figsize=(10, 5))
    sns.lineplot(x=window_df['timestamp'], y=window_df['temp'], 
                color='black', linestyle='-', label='Temperature', alpha=0.1)
    sns.lineplot(x=window_df['timestamp'], y=window_df['rolling_avg'], 
                color='orange', label=f'Rolling Avg (window={window_size})')
    plt.fill_between(window_df['timestamp'], 
                    window_df['bollinger_lower'], 
                    window_df['bollinger_upper'],
                    color='grey', alpha=0.3, label=f'Bollinger Bands (±3σ, window={window_size})')

    plt.title(f'Temperature Plot - Last {title_suffix} (Rolling Window: {window_size})')
    plt.xlabel('Timestamp')
    plt.ylabel('Temperature')
    plt.grid(True)
    plt.xticks(rotation=45)
    plt.tight_layout()
    
    # Save to window-specific directory
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
for i, (window_name, settings) in enumerate(tqdm(time_windows.items(), desc="Rendering Time Windows")):
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
