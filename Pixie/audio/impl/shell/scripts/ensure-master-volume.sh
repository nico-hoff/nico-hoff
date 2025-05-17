#!/bin/bash

# Set ALSA master to 100%
amixer -c 0 set PCM 100% &>/dev/null

# Set PulseAudio master sink to 100%
sudo -u pulse pactl set-sink-volume @DEFAULT_SINK@ 100% &>/dev/null 