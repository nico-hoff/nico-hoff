#!/bin/bash

function usage {
  echo "Usage: $0 [restart|status|spotify-volume|airplay-volume|bluetooth] [volume-value|command] [device-id]"
  echo ""
  echo "Commands:"
  echo "  restart                       Restart audio services"
  echo "  status                        Show status of audio services"
  echo "  spotify-volume [0-100]        Set Spotify volume"
  echo "  airplay-volume [0-100]        Set AirPlay volume"
  echo "  bluetooth list                List paired Bluetooth devices"
  echo "  bluetooth connect [device-id] Connect to a paired Bluetooth device"
  echo "  bluetooth disconnect          Disconnect from connected Bluetooth device"
  echo "  bluetooth scan                Scan for new Bluetooth devices"
  echo "  bluetooth pair [device-id]    Pair with a found Bluetooth device"
  exit 1
}

case "$1" in
  restart)
    echo "Restarting audio services..."
    sudo systemctl restart shairport-sync.service
    sudo systemctl restart librespot.service
    ;;
  status)
    echo "=== SERVICES STATUS ==="
    sudo systemctl status shairport-sync.service --no-pager
    sudo systemctl status librespot.service --no-pager
    sudo systemctl status bluetooth.service --no-pager
    ;;
  spotify-volume)
    if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 0 ] && [ "$2" -le 100 ]; then
      SINK_ID=$(sudo -u pulse pactl list sink-inputs short | grep librespot | awk '{print $1}')
      if [ -n "$SINK_ID" ]; then
        sudo -u pulse pactl set-sink-input-volume "$SINK_ID" "$2%"
        echo "Spotify volume set to $2%"
      else
        echo "No Spotify stream found"
      fi
    else
      usage
    fi
    ;;
  airplay-volume)
    if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 0 ] && [ "$2" -le 100 ]; then
      SINK_ID=$(sudo -u pulse pactl list sink-inputs short | grep shairport | awk '{print $1}')
      if [ -n "$SINK_ID" ]; then
        sudo -u pulse pactl set-sink-input-volume "$SINK_ID" "$2%"
        echo "AirPlay volume set to $2%"
      else
        echo "No AirPlay stream found"
      fi
    else
      usage
    fi
    ;;
  bluetooth)
    case "$2" in
      list)
        echo "=== PAIRED BLUETOOTH DEVICES ==="
        bluetoothctl paired-devices
        ;;
      connect)
        if [ -z "$3" ]; then
          echo "Error: Please provide a device ID to connect to."
          usage
        else
          echo "Connecting to Bluetooth device $3..."
          bluetoothctl connect "$3"
        fi
        ;;
      disconnect)
        CONNECTED_DEVICE=$(bluetoothctl devices | while read -r line; do
          device_id=$(echo "$line" | awk '{print $2}')
          is_connected=$(bluetoothctl info "$device_id" | grep "Connected:" | awk '{print $2}')
          
          if [ "$is_connected" = "yes" ]; then
            echo "$device_id"
            break
          fi
        done)
        
        if [ -n "$CONNECTED_DEVICE" ]; then
          echo "Disconnecting from Bluetooth device $CONNECTED_DEVICE..."
          bluetoothctl disconnect "$CONNECTED_DEVICE"
        else
          echo "No connected Bluetooth device found."
        fi
        ;;
      scan)
        echo "Scanning for Bluetooth devices for 10 seconds..."
        echo "Press Ctrl+C to stop scanning early."
        bluetoothctl scan on &
        SCAN_PID=$!
        sleep 10
        kill $SCAN_PID 2>/dev/null || true
        bluetoothctl scan off
        echo "Scan complete. Found devices:"
        bluetoothctl devices
        ;;
      pair)
        if [ -z "$3" ]; then
          echo "Error: Please provide a device ID to pair with."
          usage
        else
          echo "Pairing with Bluetooth device $3..."
          bluetoothctl pair "$3"
          echo "Attempting to connect..."
          bluetoothctl connect "$3"
        fi
        ;;
      *)
        usage
        ;;
    esac
    ;;
  *)
    usage
    ;;
esac 