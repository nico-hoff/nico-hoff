#!/bin/bash

### 📌 1. INSTALL REQUIRED PACKAGES ###
install_dependencies() {
    echo "[+] Checking dependencies..."

    # Check and install Homebrew
    if ! command -v brew &>/dev/null; then
        echo "[!] Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install required tools
    for pkg in hashcat hcxtools wget; do
        if ! brew list --formula | grep -q "^$pkg$"; then
            echo "[+] Installing $pkg..."
            brew install $pkg
        else
            echo "[✓] $pkg is already installed."
        fi
    done

    # Download RockYou.txt if missing
    if [ ! -f rockyou.txt ]; then
        echo "[+] Downloading RockYou wordlist..."
        wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
    else
        echo "[✓] RockYou.txt is already present."
    fi
}

### 📌 2. CONVERT HANDSHAKE FILE ###
convert_handshake() {
    read -p "[?] Enter the handshake file name (e.g., handshake_wifi.pcapng): " handshake_file

    if [ ! -f "$handshake_file" ]; then
        echo "[!] Error: Handshake file not found!"
        exit 1
    fi

    echo "[+] Converting handshake to Hashcat format..."
    hcxpcapngtool -o "handshake.hc22000" "$handshake_file"
    echo "[✓] Converted file: handshake.hc22000"
}

### 📌 3. CRACK PASSWORD WITH HASHCAT ###
crack_password() {
    echo "[+] Starting Hashcat (using Apple Metal GPU)..."
    hashcat -m 22000 handshake.hc22000 rockyou.txt --force --optimized-kernel-enable
    echo "[✓] Hashcat complete! Check output for results."
}

### 📌 4. RUN THE SCRIPT ###
main() {
    install_dependencies
    convert_handshake
    crack_password
}

main