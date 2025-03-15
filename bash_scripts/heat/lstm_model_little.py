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
    # Prepare data without time filtering
    data = df['temp'].values.reshape(-1, 1)
    timestamps = df['timestamp'].values
    scaler = MinMaxScaler()
    data_scaled = scaler.fit_transform(data)
    
    # Create sequences with timestamps
    X, y, time_index = prepare_sequences(data_scaled, timestamps, sequence_length)
    
    # Split into train (70%), validation (15%), test (15%)
    train_size = int(len(X) * 0.7)
    val_size = int(len(X) * 0.15)
    
    X_train = X[:train_size]
    y_train = y[:train_size]
    X_val = X[train_size:train_size+val_size]
    y_val = y[train_size:train_size+val_size]
    X_test = X[train_size+val_size:]
    y_test = y[train_size+val_size:]
    
    # Build model with more capacity
    model = Sequential([
        LSTM(16, activation='relu', input_shape=(sequence_length, 1), 
             dropout=0.2, recurrent_dropout=0.2),
        Dense(1)
    ])
    
    model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    
    # Print model summary
    print("\nModel Architecture:")
    model.summary()
    
    print(f"\nTraining Data Shape: {X_train.shape}")
    print(f"Validation Data Shape: {X_val.shape}")
    print(f"Test Data Shape: {X_test.shape}")
    
    # Train with more epochs and adjusted batch size
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=50,  # increased epochs
        batch_size=32,  # adjusted batch size for better gradient updates
        verbose=1,
        validation_split=0.2,  # additional validation split
        shuffle=True
    )
    
    # Detailed evaluation
    test_loss = model.evaluate(X_test, y_test, verbose=1)
    print(f'\nFinal Test MSE: {test_loss:.6f}')
    
    # Print training history summary
    print("\nTraining History Summary:")
    print(f"Best validation loss: {min(history.history['val_loss']):.6f}")
    print(f"Final training loss: {history.history['loss'][-1]:.6f}")
    
    return model, scaler, history

def train_lstm_with_regressor(df, regressor_col, sequence_length=20):
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
    
    # Adjust split ratios
    train_size = int(len(X) * 0.7)
    val_size = int(len(X) * 0.15)
    
    X_train = X[:train_size]
    y_train = y[:train_size]
    X_val = X[train_size:train_size+val_size]
    y_val = y[train_size:train_size+val_size]
    X_test = X[train_size+val_size:]
    y_test = y[train_size+val_size:]
    
    # Build model with more capacity
    model = Sequential([
        LSTM(32, activation='relu', input_shape=(sequence_length, 2), 
             return_sequences=True),
        LSTM(16, activation='relu'),
        Dense(1)
    ])
    
    model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    
    # Print model summary
    print("\nModel Architecture:")
    model.summary()
    
    # Train with increased epochs and adjusted batch size
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=50,  # increased epochs
        batch_size=32,  # adjusted for better gradient updates
        verbose=1,
        shuffle=True,
        validation_split=0.2
    )
    
    # Detailed evaluation
    test_loss = model.evaluate(X_test, y_test, verbose=1)
    print(f'\nFinal Test MSE: {test_loss:.6f}')
    
    return model, (temp_scaler, reg_scaler), history

def forecast_future(model, last_sequence, steps, scaler):
    """Forecast future temperature values in batches"""
    current_sequence = last_sequence.copy()
    future_predictions = []
    
    # Create batch of sequences for prediction
    prediction_sequences = np.tile(current_sequence, (steps, 1, 1))
    
    # Make predictions in a single batch
    for i in range(steps):
        next_pred = model.predict(prediction_sequences[:i+1], verbose=0)  # suppress progress bar
        future_predictions.append(next_pred[-1])
        
        # Update sequences for next iteration
        if i < steps - 1:
            prediction_sequences[i+1:, :-1] = prediction_sequences[i+1:, 1:]
            prediction_sequences[i+1:, -1] = next_pred[-1]

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
    print(f"Total samples in dataset: {len(df)}")
    
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
