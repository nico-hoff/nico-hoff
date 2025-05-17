#!/bin/bash

echo "==== PULSEAUDIO SINKS ===="
sudo -u pulse pactl list sinks short

echo -e "\n==== AUDIO STREAMS ===="
sudo -u pulse pactl list sink-inputs short

echo -e "\n==== ALSA MIXER ===="
amixer -c 0 get PCM 