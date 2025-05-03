#!/bin/bash

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" ]]; then
  GOARCH="arm64"
elif [[ "$ARCH" == "armv7l" || "$ARCH" == "armv6l" ]]; then
  GOARCH="armv6l"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

# Set Go version and install path
GO_VERSION="1.22.2"
INSTALL_DIR="/usr/local"
GO_TARBALL="go${GO_VERSION}.linux-${GOARCH}.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"

# Download Go
echo "Downloading Go ${GO_VERSION} for ${GOARCH}..."
wget -q ${GO_URL} -O /tmp/${GO_TARBALL}

# Extract Go
echo "Installing Go..."
sudo rm -rf ${INSTALL_DIR}/go
sudo tar -C ${INSTALL_DIR} -xzf /tmp/${GO_TARBALL}
rm /tmp/${GO_TARBALL}

# Update ~/.zshrc
ZSHRC="$HOME/.zshrc"
if ! grep -q "/usr/local/go/bin" "$ZSHRC"; then
  echo "export PATH=$PATH:/usr/local/go/bin" >> "$ZSHRC"
  echo "export GOPATH=$HOME/go" >> "$ZSHRC"
  echo "export PATH=$PATH:$GOPATH/bin" >> "$ZSHRC"
  echo "Go environment added to ~/.zshrc"
else
  echo "Go environment already configured in ~/.zshrc"
fi

# Source updated zshrc
echo "Loading new environment..."
source "$ZSHRC"

# Verify installation
echo "Go installation complete:"
go version
