#!/bin/bash
# ESPHome Flash Script
# Compiles and flashes firmware to ESP32 boards

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if config file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No configuration file specified${NC}"
    echo "Usage: $0 <config.yaml> [--ota]"
    echo ""
    echo "Examples:"
    echo "  $0 outside_shutter.yaml          # Compile and flash via USB"
    echo "  $0 inside_shutter.yaml --ota     # OTA update"
    exit 1
fi

CONFIG_FILE="$1"
OTA_MODE=false

# Check for OTA flag
if [ "$2" == "--ota" ]; then
    OTA_MODE=true
fi

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file '$CONFIG_FILE' not found${NC}"
    exit 1
fi

echo -e "${GREEN}ESPHome Flash Tool${NC}"
echo "Configuration: $CONFIG_FILE"
echo ""

if [ "$OTA_MODE" = true ]; then
    echo -e "${YELLOW}Mode: OTA Update${NC}"
    echo "Running OTA update from container..."
    docker-compose exec esphome esphome run "$CONFIG_FILE"
else
    echo -e "${YELLOW}Mode: USB Flash${NC}"
    echo ""
    echo "Detecting USB serial ports..."
    
    # Detect USB serial devices (macOS)
    USB_DEVICES=$(ls /dev/cu.usbserial-* /dev/cu.SLAB_USBtoUART /dev/cu.wchusbserial* 2>/dev/null || true)
    
    if [ -z "$USB_DEVICES" ]; then
        echo -e "${RED}No USB serial devices found!${NC}"
        echo ""
        echo "Make sure your ESP32 is connected via USB."
        echo "Common device names on macOS:"
        echo "  - /dev/cu.usbserial-*"
        echo "  - /dev/cu.SLAB_USBtoUART"
        echo "  - /dev/cu.wchusbserial*"
        echo ""
        echo -e "${YELLOW}Alternative: Use OTA update after initial flash${NC}"
        echo "  $0 $CONFIG_FILE --ota"
        exit 1
    fi
    
    # If multiple devices, let user choose
    DEVICE_COUNT=$(echo "$USB_DEVICES" | wc -l | xargs)
    
    if [ "$DEVICE_COUNT" -gt 1 ]; then
        echo "Multiple USB devices found:"
        select USB_PORT in $USB_DEVICES; do
            if [ -n "$USB_PORT" ]; then
                break
            fi
        done
    else
        USB_PORT="$USB_DEVICES"
    fi
    
    echo -e "${GREEN}Using device: $USB_PORT${NC}"
    echo ""
    
    # Compile firmware
    echo "Compiling firmware..."
    docker-compose exec esphome esphome compile "$CONFIG_FILE"
    
    # Flash using esptool (needs to run outside container on macOS)
    echo ""
    echo "Flashing to device..."
    
    # Find the compiled binary
    DEVICE_NAME=$(grep "name:" "$CONFIG_FILE" | head -1 | awk '{print $2}' | tr -d '"')
    FIRMWARE_BIN=".esphome/build/$DEVICE_NAME/.pioenvs/$DEVICE_NAME/firmware.bin"
    
    if [ ! -f "$FIRMWARE_BIN" ]; then
        echo -e "${RED}Error: Compiled firmware not found at $FIRMWARE_BIN${NC}"
        exit 1
    fi
    
    # Check if esptool is available on host
    if ! command -v esptool.py &> /dev/null; then
        echo -e "${YELLOW}esptool.py not found on host system${NC}"
        echo "Install with: pip install esptool"
        echo ""
        echo "Or use ESPHome Web Installer: https://web.esphome.io/"
        exit 1
    fi
    
    # Flash the firmware
    esptool.py --port "$USB_PORT" write_flash 0x10000 "$FIRMWARE_BIN"
    
    echo ""
    echo -e "${GREEN}✓ Flash complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Monitor logs: ./scripts/logs.sh $CONFIG_FILE"
    echo "  2. Future updates: $0 $CONFIG_FILE --ota"
fi
