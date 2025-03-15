import pandas as pd
import numpy as np
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
from tensorflow.keras.optimizers import Adam

def prepare_sequences(data, seq_length):
    X, y = [], []
    for i in range(len(data) - seq_length):
        X.append(data[i:(i + seq_length)])
        y.append(data[i + seq_length])
    return np.array(X), np.array(y)

def train_basic_lstm(df, sequence_length=60):
    # Prepare data
    data = df['temp'].values.reshape(-1, 1)
    scaler = MinMaxScaler()
    data_scaled = scaler.fit_transform(data)
    
    # Create sequences
    X, y = prepare_sequences(data_scaled, sequence_length)
    
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
        LSTM(50, activation='relu', input_shape=(sequence_length, 1)),
        Dense(1)
    ])
    
    model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    
    # Train
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=50,
        batch_size=32,
        verbose=1
    )
    
    # Evaluate
    test_loss = model.evaluate(X_test, y_test, verbose=0)
    print(f'Test MSE: {test_loss}')
    
    return model, scaler, history

def train_lstm_with_regressor(df, regressor_col, sequence_length=60):
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
        LSTM(50, activation='relu', input_shape=(sequence_length, 2)),
        Dense(1)
    ])
    
    model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    
    # Train
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=50,
        batch_size=32,
        verbose=1
    )
    
    # Evaluate
    test_loss = model.evaluate(X_test, y_test, verbose=0)
    print(f'Test MSE: {test_loss}')
    
    return model, (temp_scaler, reg_scaler), history

if __name__ == "__main__":
    print("\nLoading data...")
    df = pd.read_csv('data/raw/temp_log_2.csv', parse_dates=['timestamp'])
    
    print("\nTraining basic LSTM model...")
    model, scaler, history = train_basic_lstm(df)
    
    print("\nTraining LSTM model with CPU metrics...")
    # Train with CPU MHz as regressor
    print("\nTraining with CPU MHz as regressor...")
    model_mhz, scalers_mhz, history_mhz = train_lstm_with_regressor(df, 'MHz')
    
    # Train with CPU load as regressor
    print("\nTraining with CPU load as regressor...")
    model_load, scalers_load, history_load = train_lstm_with_regressor(df, 'cpu_load_percent')
    
    # Train with both CPU metrics
    print("\nTraining with both CPU metrics...")
    # Prepare data for combined features
    temp_data = df['temp'].values.reshape(-1, 1)
    mhz_data = df['MHz'].values.reshape(-1, 1)
    load_data = df['cpu_load_percent'].values.reshape(-1, 1)
    
    # Scale all features
    temp_scaler = MinMaxScaler()
    mhz_scaler = MinMaxScaler()
    load_scaler = MinMaxScaler()
    
    temp_scaled = temp_scaler.fit_transform(temp_data)
    mhz_scaled = mhz_scaler.fit_transform(mhz_data)
    load_scaled = load_scaler.fit_transform(load_data)
    
    # Combine all features
    combined_data = np.hstack((temp_scaled, mhz_scaled, load_scaled))
    
    # Create sequences for combined features
    sequence_length = 60
    X, y = [], []
    for i in range(len(combined_data) - sequence_length):
        X.append(combined_data[i:(i + sequence_length)])
        y.append(temp_scaled[i + sequence_length])
    
    X = np.array(X)
    y = np.array(y)
    
    # Split data as before
    train_size = int(len(X) * 0.5)
    val_size = int(len(X) * 0.3)
    
    X_train = X[:train_size]
    y_train = y[:train_size]
    X_val = X[train_size:train_size+val_size]
    y_val = y[train_size:train_size+val_size]
    X_test = X[train_size+val_size:]
    y_test = y[train_size+val_size:]
    
    # Build and train model with all features
    model_combined = Sequential([
        LSTM(50, activation='relu', input_shape=(sequence_length, 3)),
        Dense(1)
    ])
    
    model_combined.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    
    history_combined = model_combined.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=50,
        batch_size=32,
        verbose=1
    )
    
    test_loss = model_combined.evaluate(X_test, y_test, verbose=0)
    print(f'Combined features test MSE: {test_loss}')
    
    print("\nTraining completed!")
