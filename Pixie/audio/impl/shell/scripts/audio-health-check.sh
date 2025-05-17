#!/bin/bash

# Audio Health Check Script for Pixie
# Tests if all audio-related systems are available and functioning

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

echo -e "${BLUE}====== Pixie Audio Health Check =====${NC}"
echo "Checking all audio systems..."
echo ""

# Function to check if a service is active
check_service() {
    local service_name=$1
    local service_desc=$2
    echo -n "Checking $service_desc... "
    
    if systemctl is-active --quiet "$service_name"; then
        echo -e "${GREEN}RUNNING${NC}"
        return 0
    else
        echo -e "${RED}NOT RUNNING${NC}"
        return 1
    fi
}

# Function to check audio devices
check_audio_devices() {
    echo -n "Checking ALSA audio devices... "
    
    if aplay -l | grep -q "bcm2835 ALSA"; then
        echo -e "${GREEN}FOUND${NC}"
        return 0
    else
        echo -e "${RED}NOT FOUND${NC}"
        return 1
    fi
}

# Function to check PulseAudio modules
check_pulse_modules() {
    local module_name=$1
    local module_desc=$2
    echo -n "Checking PulseAudio $module_desc... "
    
    if sudo -u pulse pactl list modules | grep -q "$module_name"; then
        echo -e "${GREEN}LOADED${NC}"
        return 0
    else
        echo -e "${RED}NOT LOADED${NC}"
        return 1
    fi
}

# Function to check if a process is running
check_process() {
    local process_name=$1
    local process_desc=$2
    echo -n "Checking $process_desc process... "
    
    if pgrep -f "$process_name" > /dev/null; then
        echo -e "${GREEN}RUNNING${NC}"
        return 0
    else
        echo -e "${RED}NOT RUNNING${NC}"
        return 1
    fi
}

# Function to check Bluetooth setup
check_bluetooth() {
    echo -n "Checking Bluetooth adapter... "
    
    if hciconfig hci0 up > /dev/null 2>&1; then
        echo -e "${GREEN}AVAILABLE${NC}"
        
        echo -n "Checking Bluetooth audio class... "
        CLASS=$(hciconfig hci0 | grep "Class" | awk '{print $2}')
        
        if [ "$CLASS" == "0x240414" ]; then
            echo -e "${GREEN}CORRECT (Audio Sink)${NC}"
        else
            echo -e "${YELLOW}INCORRECT ($CLASS)${NC}"
            return 1
        fi
        
        return 0
    else
        echo -e "${RED}NOT AVAILABLE${NC}"
        return 1
    fi
}

# Function to check if service is enabled at boot
check_service_enabled() {
    local service_name=$1
    local service_desc=$2
    echo -n "Checking if $service_desc starts at boot... "
    
    if systemctl is-enabled --quiet "$service_name"; then
        echo -e "${GREEN}ENABLED${NC}"
        return 0
    else
        echo -e "${YELLOW}NOT ENABLED${NC}"
        return 1
    fi
}

# Main Test Sections
echo -e "${BLUE}== Core Audio System ==${NC}"
check_audio_devices
check_process "pulseaudio" "PulseAudio"

echo -e "\n${BLUE}== PulseAudio Configuration ==${NC}"
check_pulse_modules "module-alsa" "ALSA module"
check_pulse_modules "module-bluetooth" "Bluetooth module"
check_pulse_modules "module-native-protocol-unix" "Unix protocol module"

echo -e "\n${BLUE}== Audio Services ==${NC}"
SHAIRPORT_STATUS=$(check_service "shairport-sync.service" "Shairport Sync (AirPlay)")
LIBRESPOT_STATUS=$(check_service "librespot.service" "Librespot (Spotify)")
check_service "ensure-master-volume.timer" "Master Volume Service"

echo -e "\n${BLUE}== Bluetooth Configuration ==${NC}"
check_bluetooth
check_service "bluetooth.service" "Bluetooth service"
check_service "bluetooth-boot.service" "Bluetooth boot service"
check_service "a2dp-agent.service" "A2DP agent service"
check_service "simple-agent.service" "Bluetooth simple agent"

echo -e "\n${BLUE}== Boot Configuration ==${NC}"
check_service_enabled "shairport-sync.service" "Shairport Sync (AirPlay)"
check_service_enabled "librespot.service" "Librespot (Spotify)"
check_service_enabled "bluetooth.service" "Bluetooth service"
check_service_enabled "bluetooth-boot.service" "Bluetooth boot service"
check_service_enabled "a2dp-agent.service" "A2DP agent service"
check_service_enabled "simple-agent.service" "Bluetooth simple agent"

# Test if audio output works
echo -e "\n${BLUE}== Audio Output Test ==${NC}"
echo -n "Testing audio output... "

# Generate a test tone and play it
if which sox > /dev/null 2>&1; then
    play -n synth 0.5 sine 440 2>/dev/null && echo -e "${GREEN}SUCCESS${NC}" || echo -e "${YELLOW}FAILED (Could not play test tone)${NC}"
else
    echo -e "${YELLOW}SKIPPED (SoX not installed)${NC}"
    echo "To install: sudo apt-get install sox"
fi

# Check for issues in logs
echo -e "\n${BLUE}== Log Analysis ==${NC}"
echo "Checking for errors in logs..."

# Check PulseAudio logs
echo -n "PulseAudio issues: "
PULSE_ERRORS=$(journalctl -u pulseaudio --since "1 hour ago" | grep -i "error\|fail" | wc -l)
if [ "$PULSE_ERRORS" -gt 0 ]; then
    echo -e "${YELLOW}$PULSE_ERRORS errors found${NC}"
    echo "Run 'journalctl -u pulseaudio | grep -i \"error\|fail\"' for details"
else
    echo -e "${GREEN}None${NC}"
fi

# Check Shairport logs
echo -n "Shairport issues: "
SHAIRPORT_ERRORS=$(journalctl -u shairport-sync --since "1 hour ago" | grep -i "error\|fail" | wc -l)
if [ "$SHAIRPORT_ERRORS" -gt 0 ]; then
    echo -e "${YELLOW}$SHAIRPORT_ERRORS errors found${NC}"
    echo "Run 'journalctl -u shairport-sync | grep -i \"error\|fail\"' for details"
else
    echo -e "${GREEN}None${NC}"
fi

# Check Librespot logs
echo -n "Librespot issues: "
LIBRESPOT_ERRORS=$(journalctl -u librespot --since "1 hour ago" | grep -i "error\|fail" | wc -l)
if [ "$LIBRESPOT_ERRORS" -gt 0 ]; then
    echo -e "${YELLOW}$LIBRESPOT_ERRORS errors found${NC}"
    echo "Run 'journalctl -u librespot | grep -i \"error\|fail\"' for details"
else
    echo -e "${GREEN}None${NC}"
fi

# Check Bluetooth logs
echo -n "Bluetooth issues: "
BT_ERRORS=$(journalctl -u bluetooth --since "1 hour ago" | grep -i "error\|fail" | wc -l)
if [ "$BT_ERRORS" -gt 0 ]; then
    echo -e "${YELLOW}$BT_ERRORS errors found${NC}"
    echo "Run 'journalctl -u bluetooth | grep -i \"error\|fail\"' for details"
else
    echo -e "${GREEN}None${NC}"
fi

# Summary
echo -e "\n${BLUE}====== Summary ======${NC}"
TOTAL_CHECKS=0
FAILED_CHECKS=0

# Calculate status
if [[ "$SHAIRPORT_STATUS" == *"NOT RUNNING"* ]]; then
    echo -e "AirPlay: ${RED}NOT AVAILABLE${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
    echo -e "AirPlay: ${GREEN}AVAILABLE${NC}"
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [[ "$LIBRESPOT_STATUS" == *"NOT RUNNING"* ]]; then
    echo -e "Spotify Connect: ${RED}NOT AVAILABLE${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
    echo -e "Spotify Connect: ${GREEN}AVAILABLE${NC}"
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# Check Bluetooth comprehensive status
BT_STATUS=$(systemctl is-active bluetooth.service && systemctl is-active bluetooth-boot.service && systemctl is-active a2dp-agent.service && systemctl is-active simple-agent.service)
if [ "$BT_STATUS" == "active
active
active
active" ]; then
    echo -e "Bluetooth: ${GREEN}AVAILABLE${NC}"
else
    echo -e "Bluetooth: ${RED}NOT FULLY AVAILABLE${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# Calculate success rate
SUCCESS_RATE=$((100 - (FAILED_CHECKS * 100 / TOTAL_CHECKS)))
echo -e "Audio Services Health: ${SUCCESS_RATE}% operational"

echo -e "\nFor detailed status information, run:"
echo "  /home/pi/bin/audio-status.sh"
echo "To control audio services, run:"
echo "  /home/pi/bin/audio-control.sh"
echo "To manually configure Bluetooth, run:"
echo "  /home/pi/bin/bluetooth-config.sh"

exit $FAILED_CHECKS 