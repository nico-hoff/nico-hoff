# Spotify Access Point

## Librespot selbst kompilieren

## 1. Rust installiert?

```bash
which cargo || echo "Rust not installed"
```

## 2. Install the necessary dependencies for Librespot

```bash 
sudo apt-get update && sudo apt-get install -y build-essential libasound2-dev pkg-config
```

## 3. Install Librespot using Cargo

```bash
cargo install librespot 
```

if fails

```bash
cargo install librespot --locked
```

## 3. Binary zu Path hinzufügen

```bash
nano ~/.zshrc
```

append

```
export PATH=$PATH:$HOME/.cargo/bin
```

## 3. Kompiliertes Binary verwenden:

```bash
librespot --name "Pixie" —-bitrate 320 --enable-volume-normalisation —-initial-volume 60
```