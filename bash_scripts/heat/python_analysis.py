import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime, timedelta

# Load the data
df = pd.read_csv('data/temp_log.csv', parse_dates=['timestamp'])

# Boxplot for temperature distribution
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
df = df[df['timestamp'].dt.date == today]

# Define a function to split the dataframe based on gaps in the timestamps
def split_dataframe(df, gap_threshold=timedelta(minutes=1)):
    dataframes = []
    current_df = [df.iloc[0]]
    
    for i in range(1, len(df)):
        if df.iloc[i]['timestamp'] - df.iloc[i-1]['timestamp'] > gap_threshold:
            dataframes.append(pd.DataFrame(current_df))
            current_df = [df.iloc[i]]
        else:
            current_df.append(df.iloc[i])
    
    dataframes.append(pd.DataFrame(current_df))
    return dataframes

# Split the dataframe
dfs = split_dataframe(df)

# Plot each dataframe
for i, df_split in enumerate(dfs):
    # Save the segmented data to CSV
    df_split.to_csv(f'data/temperature_data_{i}.csv', index=False)
    
    # Compute rolling average and Bollinger bands
    df_split['rolling_avg'] = df_split['temp'].rolling(window=20, min_periods=1).mean()
    df_split['rolling_std'] = df_split['temp'].rolling(window=20, min_periods=1).std()
    df_split['bollinger_upper'] = df_split['rolling_avg'] + (3 * df_split['rolling_std'])
    df_split['bollinger_lower'] = df_split['rolling_avg'] - (3 * df_split['rolling_std'])
    
    plt.figure(figsize=(10, 5))
    # Plot original temperature
    sns.lineplot(x=df_split['timestamp'], y=df_split['temp'], color='black',linestyle='-', label='Temperature', alpha=0.1)
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
    plt.savefig(f'graphs/temperature_plot_{i+1}.png')
    plt.show()