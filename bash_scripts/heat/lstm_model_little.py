import pandas as pd
import numpy as np
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
from tensorflow.keras.optimizers import Adam
import matplotlib.pyplot as plt
from datetime import timedelta

def prepare_sequences(data, timestamps, seq_length):
    X, y = [], []
    time_index = []
    for i in range(len(data) - seq_length):
        X.append(data[i:(i + seq_length)])
        y.append(data[i + seq_length])
        time_index.append(pd.to_datetime(timestamps[i + seq_length]))  # Convert to pandas datetime
    return np.array(X), np.array(y), pd.DatetimeIndex(time_index)  # Use DatetimeIndex

def train_basic_lstm(df, sequence_length=20):
    # Get last 4 hours of data
    last_timestamp = df['timestamp'].max()
    start_timestamp = last_timestamp - timedelta(hours=4)
    df_filtered = df[df['timestamp'] >= start_timestamp].copy()
    
    # Prepare data
    data = df_filtered['temp'].values.reshape(-1, 1)
    timestamps = df_filtered['timestamp'].values
    scaler = MinMaxScaler()
    data_scaled = scaler.fit_transform(data)
    
    # Create sequences with timestamps
    X, y, time_index = prepare_sequences(data_scaled, timestamps, sequence_length)
    
    # Split into train (50%), validation (30%), test (20%)
    train_size = int(len(X) * 0.5)
    val_size = int(len(X) * 0.3)
    
    X_train = X[:train_size]
    y_train = y[:train_size]
    X_val = X[train_size:train_size+val_size]
    y_val = y[train_size:train_size+val_size]
    X_test = X[train_size+val_size:]
    y_test = y[train_size+val_size:]
    
    # Build model
    model = Sequential([
        LSTM(16, activation='relu', input_shape=(sequence_length, 1)),  # reduced from 50
        Dense(1)
    ])
    
    model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    
    # Train with reduced epochs and larger batch size
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=15,  # reduced from 50
        batch_size=64,  # increased from 32
        verbose=1
    )
    
    # Evaluate
    test_loss = model.evaluate(X_test, y_test, verbose=0)
    print(f'Test MSE: {test_loss}')
    
    return model, scaler, history

def train_lstm_with_regressor(df, regressor_col, sequence_length=20):  # reduced from 60
    # Prepare data
    temp_data = df['temp'].values.reshape(-1, 1)
    reg_data = df[regressor_col].values.reshape(-1, 1)
    
    # Scale both features
    temp_scaler = MinMaxScaler()
    reg_scaler = MinMaxScaler()
    
    temp_scaled = temp_scaler.fit_transform(temp_data)
    reg_scaled = reg_scaler.fit_transform(reg_data)
    
    # Combine features
    combined_data = np.hstack((temp_scaled, reg_scaled))
    
    # Create sequences
    X, y = [], []
    for i in range(len(combined_data) - sequence_length):
        X.append(combined_data[i:(i + sequence_length)])
        y.append(temp_scaled[i + sequence_length])
    
    X = np.array(X)
    y = np.array(y)
    
    # Split data
    train_size = int(len(X) * 0.5)
    val_size = int(len(X) * 0.3)
    
    X_train = X[:train_size]
    y_train = y[:train_size]
    X_val = X[train_size:train_size+val_size]
    y_val = y[train_size:train_size+val_size]
    X_test = X[train_size+val_size:]
    y_test = y[train_size+val_size:]
    
    # Build model
    model = Sequential([
        LSTM(16, activation='relu', input_shape=(sequence_length, 2)),  # reduced from 50
        Dense(1)
    ])
    
    model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    
    # Train with reduced epochs and larger batch size
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=15,  # reduced from 50
        batch_size=64,  # increased from 32
        verbose=1
    )
    
    # Evaluate
    test_loss = model.evaluate(X_test, y_test, verbose=0)
    print(f'Test MSE: {test_loss}')
    
    return model, (temp_scaler, reg_scaler), history

def forecast_future(model, last_sequence, steps, scaler):
    """Forecast future temperature values"""
    current_sequence = last_sequence.copy()
    future_predictions = []

    for _ in range(steps):
        # Get prediction for next step
        next_pred = model.predict(current_sequence.reshape(1, current_sequence.shape[0], current_sequence.shape[1]))
        future_predictions.append(next_pred[0])
        
        # Update sequence by removing first element and adding prediction
        current_sequence = np.roll(current_sequence, -1, axis=0)
        current_sequence[-1] = next_pred

    return np.array(future_predictions)

def make_predictions(model, scaler, X_test, y_test, timestamps_test):
    # Make predictions for test data
    predictions = model.predict(X_test)
    
    # Calculate forecast steps (1/3 of total steps)
    forecast_steps = len(predictions) // 3
    
    # Get the last sequence for forecasting
    last_sequence = X_test[-1]
    future_pred = forecast_future(model, last_sequence, forecast_steps, scaler)
    
    # Inverse transform predictions
    predictions = scaler.inverse_transform(predictions)
    y_test = scaler.inverse_transform(y_test)
    future_pred = scaler.inverse_transform(future_pred)
    
    # Create future timestamps
    last_timestamp = pd.to_datetime(timestamps_test[-1])  # Convert to pandas datetime
    future_timestamps = pd.date_range(
        start=last_timestamp, 
        periods=forecast_steps + 1, 
        freq='S'
    )[1:]  # exclude start to avoid duplicate
    
    # Plot results
    plt.figure(figsize=(12, 6))
    plt.plot(timestamps_test, y_test, label='Actual Temperature', color='blue')
    plt.plot(timestamps_test, predictions, label='Predicted Temperature', color='red', alpha=0.7)
    plt.plot(future_timestamps, future_pred, label='Forecasted Temperature', 
             color='green', linestyle='--', alpha=0.7)
    plt.axvline(x=last_timestamp, color='gray', linestyle=':', label='Forecast Start')
    plt.title('Temperature Prediction and Forecast (Last 4 Hours)')
    plt.xlabel('Time')
    plt.ylabel('Temperature (°C)')
    plt.legend()
    plt.grid(True)
    plt.gcf().autofmt_xdate()  # Rotate and align the tick labels
    plt.savefig('temperature_prediction.png')
    plt.close()
    
    return predictions, y_test, future_pred

if __name__ == "__main__":
    print("\nLoading data...")
    df = pd.read_csv('data/raw/temp_log_2.csv', parse_dates=['timestamp'])
    
    print("\nTraining basic LSTM model...")
    model, scaler, history = train_basic_lstm(df)
    
    # Prepare test data for last 4 hours
    last_timestamp = df['timestamp'].max()
    start_timestamp = last_timestamp - timedelta(hours=4)
    df_filtered = df[df['timestamp'] >= start_timestamp].copy()
    
    data = df_filtered['temp'].values.reshape(-1, 1)
    data_scaled = scaler.transform(data)
    X, y, timestamps = prepare_sequences(data_scaled, df_filtered['timestamp'].values, 20)
    
    # Use last 20% of data for testing
    test_split = int(len(X) * 0.8)
    X_test = X[test_split:]
    y_test = y[test_split:]
    timestamps_test = timestamps[test_split:]
    
    print("\nMaking predictions and plotting results...")
    predictions, y_test, future_predictions = make_predictions(
        model, scaler, X_test, y_test, timestamps_test)
    
    print("\nTraining completed! Check 'temperature_prediction.png' for results.")
    print(f"Forecasted {len(future_predictions)} steps into the future.")
