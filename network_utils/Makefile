.PHONY: build install clean test

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
BINARY_NAME=network_utils
INSTALL_PATH=/usr/local/bin

all: test build

build:
	$(GOBUILD) -o $(BINARY_NAME) -v

test:
	$(GOTEST) -v ./...

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

run:
	$(GOBUILD) -o $(BINARY_NAME) -v
	./$(BINARY_NAME)

install: build
	install -m 755 $(BINARY_NAME) $(INSTALL_PATH)

uninstall:
	rm -f $(INSTALL_PATH)/$(BINARY_NAME)

deps:
	$(GOGET) -v ./...
	$(GOGET) github.com/spf13/cobra
	$(GOGET) github.com/fatih/color
	$(GOGET) github.com/google/gopacket
	$(GOGET) golang.org/x/sync/errgroup 