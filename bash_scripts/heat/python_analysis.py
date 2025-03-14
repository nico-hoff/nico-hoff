import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from tqdm import tqdm

# Load the data
print("Loading data...")
df = pd.read_csv('data/raw/temp_log.csv', parse_dates=['timestamp'])

# Boxplot for temperature distribution
print("Plotting temperature distribution...")
plt.figure(figsize=(6, 4))
sns.boxplot(y=df['temp'])
plt.title('Temperature Distribution')
plt.ylabel('Temperature')
plt.grid(True, axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig(f'graphs/temperature_boxplot_total.png')
plt.show()

# Filter the dataframe for rows where the timestamp is equal to today
today = datetime.now().date()
yesterday = today - timedelta(days=1)
df = df[(df['timestamp'].dt.date >= today - timedelta(days=1))]

# Define a function to split the dataframe based on gaps in the timestamps
def split_dataframe(df, gap_threshold=timedelta(minutes=1), duration_limit=timedelta(hours=24)):
    dataframes = []
    current_df = [df.iloc[0]]
    start_time = df.iloc[0]['timestamp']
    
    for i in tqdm(range(1, len(df)), desc="Splitting"):
        current_time = df.iloc[i]['timestamp']
        
        # Check for gap threshold or duration limit
        if (current_time - df.iloc[i-1]['timestamp'] > gap_threshold) or \
           (current_time - start_time > duration_limit):
            dataframes.append(pd.DataFrame(current_df))
            current_df = [df.iloc[i]]
            start_time = current_time
        else:
            current_df.append(df.iloc[i])
    
    dataframes.append(pd.DataFrame(current_df))
    return dataframes

# Split the dataframe
dfs = split_dataframe(df)

# Plot each dataframe
for i, df_split in enumerate(tqdm(dfs, desc="Processing dataframes")):
    
    # Compute rolling average and Bollinger bands
    df_split['rolling_avg'] = None
    df_split['rolling_std'] = None
    df_split['bollinger_upper'] = None
    df_split['bollinger_lower'] = None
    
    # Process analytics with progress bar
    for i, row in tqdm(df_split.iterrows(), total=len(df_split), desc="Calculating analytics"):
        if i >= len(df_split) - 1:  # Skip last row to avoid index errors
            continue
        window = df_split['temp'].iloc[max(0, i-19):i+1]  # Get up to 20 previous values
        df_split.at[i, 'rolling_avg'] = window.mean()
        df_split.at[i, 'rolling_std'] = window.std()
        df_split.at[i, 'bollinger_upper'] = df_split.at[i, 'rolling_avg'] + (3 * df_split.at[i, 'rolling_std'])
        df_split.at[i, 'bollinger_lower'] = df_split.at[i, 'rolling_avg'] - (3 * df_split.at[i, 'rolling_std'])
    
    # Save the segmented data to CSV
    date_str = df_split['timestamp'].iloc[0].strftime('%Y%m%d')
    df_split.to_csv(f'data/processed/stage_temp_data_{date_str}_{i}.csv', index=False)
    
    plt.figure(figsize=(10, 5))
    # Plot original temperature
    sns.lineplot(x=df_split['timestamp'], y=df_split['temp'], color='black', linestyle='-', label='Temperature', alpha=0.1)
    # Plot rolling average
    sns.lineplot(x=df_split['timestamp'], y=df_split['rolling_avg'], color='orange', label='Rolling Avg (t=20)')
    # Plot Bollinger Bands as a filled area
    plt.fill_between(df_split['timestamp'], df_split['bollinger_lower'], df_split['bollinger_upper'], color='grey', alpha=0.3, label='Bollinger Bands (std*3)')
    
    plt.title(f'Temperature Plot {i+1}')
    plt.xlabel('Timestamp')
    plt.ylabel('Temperature')
    plt.grid(True)
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'graphs/temperature_plot_{i}.png')
    plt.show()