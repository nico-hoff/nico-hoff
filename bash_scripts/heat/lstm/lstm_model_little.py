import pandas as pd
import numpy as np
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
from tensorflow.keras.optimizers import Adam
import matplotlib.pyplot as plt
from datetime import timedelta
import os
import getpass

# intense_ratio = 0.01 # less intense training
intense_ratio = 0.0001 # more intense training 
# training_ratio = 0.01 # Default
training_ratio = 0.002 # Default

# Hilfsfunktion zur Erstellung von Sequenzen für das LSTM-Modell
def prepare_sequences(data, timestamps, seq_length):
    print(f"\nPreparing sequences with length {seq_length}...")
    X, y, time_index = [], [], []
    total_sequences = len(data) - seq_length
    for i in range(total_sequences):
        if i % (total_sequences // 10) == 0:  # Progress update every 10%
            print(f"Processing sequences: {(i/total_sequences)*100:.1f}% complete")
        X.append(data[i:(i + seq_length)])
        y.append(data[i + seq_length, 0])
        time_index.append(pd.to_datetime(timestamps[i + seq_length]))
    print("Sequence preparation complete!")
    return np.array(X), np.array(y), pd.DatetimeIndex(time_index)

# Funktion zur Berechnung optimaler Trainingsparameter
def calculate_training_params(dataset_length, intense_ratio=0.01):
    print("\nCalculating optimal training parameters...")
    ratio = intense_ratio
    batch_size = min(max(int(np.sqrt(dataset_length) * ratio * 10), 16), 128)
    batch_size = int(batch_size / 8) * 8  # Batch-Größe für optimale Performance anpassen
    epochs = min(max(int(np.log10(dataset_length) * (1/ratio)), 5), 50)
    print(f"Calculated parameters: batch_size={batch_size}, epochs={epochs}")
    return epochs, batch_size

# Trainingsfunktion für LSTM-Modell mit Temperatur- und MHz-Wert als Features
def train_lstm(df, sequence_length=20, training_ratio=training_ratio):
    print("\nInitializing LSTM training process...")
    print(f"Dataset size: {len(df)} rows")
    print(f"Sequence length: {sequence_length}")
    
    print("\nExtracting and scaling features...")
    data = df[['temp', 'avg_mhz']].values
    timestamps = df['timestamp'].values
    
    # Skalierung der Features
    scaler_temp, scaler_mhz = MinMaxScaler(), MinMaxScaler()
    data_scaled = np.column_stack((
        scaler_temp.fit_transform(data[:, 0].reshape(-1, 1)),
        scaler_mhz.fit_transform(data[:, 1].reshape(-1, 1))
    ))
    print("Feature scaling complete!")

    # Erstellung von Sequenzen
    X, y, time_index = prepare_sequences(data_scaled, timestamps, sequence_length)

    print("\nSplitting dataset...")
    train_size = int(len(X) * 0.7)
    val_size = int(len(X) * 0.15)
    print(f"Training set size: {train_size}")
    print(f"Validation set size: {val_size}")
    print(f"Test set size: {len(X) - train_size - val_size}")

    X_train, y_train = X[:train_size], y[:train_size]
    X_val, y_val = X[train_size:train_size + val_size], y[train_size:train_size + val_size]
    X_test, y_test = X[train_size + val_size:], y[train_size + val_size:]

    print("\nBuilding LSTM model...")
    model = Sequential([
        LSTM(32, activation='relu', input_shape=(sequence_length, 2), dropout=0.2, recurrent_dropout=0.2),
        Dense(16, activation='relu'),
        Dense(1)
    ])
    model.compile(optimizer=Adam(learning_rate=0.001), loss='mse')
    print("Model architecture:")
    model.summary()

    # Trainingsparameter berechnen
    epochs, batch_size = calculate_training_params(len(df), training_ratio)

    print("\nStarting model training...")
    # Modell trainieren
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=epochs,
        batch_size=batch_size,
        verbose=1,
        shuffle=True
    )

    print("\nEvaluating model on test set...")
    # Modell bewerten
    test_loss = model.evaluate(X_test, y_test, verbose=1)
    print(f'Final Test MSE: {test_loss:.6f}')

    return model, (scaler_temp, scaler_mhz), history

# Funktion zur Vorhersage zukünftiger Werte
def forecast_future(model, last_sequence, steps, scaler, mean_mhz):
    print(f"\nGenerating future forecast for {steps} steps...")
    current_sequence = last_sequence.copy()
    future_predictions = []

    # Scale the mean MHz value
    scaled_mhz = scaler[1].transform([[mean_mhz]])[0][0]

    for step in range(steps):
        if step % (steps // 5) == 0:  # Progress update every 20%
            print(f"Forecasting progress: {(step/steps)*100:.1f}%")
        next_pred = model.predict(current_sequence[np.newaxis, :, :], verbose=0)
        future_predictions.append(next_pred[0])

        # Verschieben der Sequenz und Einfügen neuer Werte
        current_sequence = np.roll(current_sequence, -1, axis=0)
        current_sequence[-1, 0] = next_pred[0]  # Temperatur aktualisieren
        current_sequence[-1, 1] = scaled_mhz    # MHz auf Durchschnitt setzen

    print("Forecast generation complete!")
    return np.array(future_predictions)

# Funktion zur Modellvorhersage und Visualisierung der Ergebnisse
def make_predictions(model, scaler, X_test, y_test, timestamps_test, mean_mhz):
    print("\nMaking predictions on test data...")
    predictions = model.predict(X_test)

    print("\nGenerating future predictions...")
    forecast_steps = len(predictions) // 3
    last_sequence = X_test[-1]
    future_pred = forecast_future(model, last_sequence, forecast_steps, scaler, mean_mhz)

    print("\nInverse transforming scaled values...")
    # Inverse Transformation der Skalierten Werte
    predictions = scaler[0].inverse_transform(predictions.reshape(-1, 1))
    y_test = scaler[0].inverse_transform(y_test.reshape(-1, 1))
    future_pred = scaler[0].inverse_transform(future_pred.reshape(-1, 1))

    print("\nPreparing visualization...")
    # Zeitachsen für Prognosen erstellen
    last_timestamp = pd.to_datetime(timestamps_test[-1])
    future_timestamps = pd.date_range(start=last_timestamp, periods=forecast_steps + 1, freq='S')[1:]

    print("Creating prediction plot...")
    # Ergebnisse visualisieren
    plt.figure(figsize=(12, 6))
    plt.plot(timestamps_test, y_test, label='Echte Temperatur', color='blue')
    plt.plot(timestamps_test, predictions, label='Vorhersage', color='red', alpha=0.7)
    plt.plot(future_timestamps, future_pred, label='Prognose', color='green', linestyle='--', alpha=0.7)
    plt.axvline(x=last_timestamp, color='gray', linestyle=':', label='Prognose-Start')
    plt.title('Temperaturvorhersage')
    plt.xlabel('Zeit')
    plt.ylabel('Temperatur (°C)')
    plt.legend()
    plt.grid(True)
    plt.gcf().autofmt_xdate()
    
    # Get OS user and create dynamic path
    os_user = getpass.getuser()
    graph_path = f'graphs/{os_user}'
    os.makedirs(graph_path, exist_ok=True)
    save_path = f'{graph_path}/temperature_prediction.png'
    
    print(f"Saving plot to '{save_path}'...")
    plt.savefig(save_path)
    plt.close()

    return predictions, y_test, future_pred

if __name__ == "__main__":
    print("\n" + "="*50)
    print("Temperature Prediction Model Training")
    print("="*50)
    
    print("\nLoading data...")
    df = pd.read_csv('data/raw/temp_log_multi.csv', parse_dates=['timestamp'])
    print(f"Dataset loaded successfully with {len(df)} records")

    print("\nInitiating LSTM model training...")
    model, (scaler_temp, scaler_mhz), history = train_lstm(df, training_ratio=0.01)

    print("\nPreparing test data from last 4 hours...")
    last_timestamp = df['timestamp'].max()
    start_timestamp = last_timestamp - timedelta(hours=4)
    df_filtered = df[df['timestamp'] >= start_timestamp].copy()
    print(f"Test dataset size: {len(df_filtered)} records")

    data = df_filtered[['temp', 'avg_mhz']].values
    data_scaled = np.column_stack((
        scaler_temp.transform(data[:, 0].reshape(-1, 1)),
        scaler_mhz.transform(data[:, 1].reshape(-1, 1))
    ))

    # Testsequenzen erstellen
    X, y, timestamps = prepare_sequences(data_scaled, df_filtered['timestamp'].values, 20)
    test_split = int(len(X) * 0.8)
    X_test, y_test, timestamps_test = X[test_split:], y[test_split:], timestamps[test_split:]

    # Calculate mean MHz before making predictions
    mean_mhz = df['avg_mhz'].mean()
    
    print("\nErstelle Vorhersagen...")
    predictions, y_test, future_predictions = make_predictions(
        model, 
        (scaler_temp, scaler_mhz), 
        X_test, 
        y_test, 
        timestamps_test,
        mean_mhz
    )

    print("\nAnalysis complete!")
    print(f"Future predictions generated: {len(future_predictions)} steps")
    print("Results have been saved to 'temperature_prediction.png'")
    print("="*50)