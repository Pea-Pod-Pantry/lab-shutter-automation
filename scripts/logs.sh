#!/bin/bash
# ESPHome Logs Script
# View real-time logs from ESPHome devices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if config file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No configuration file specified${NC}"
    echo "Usage: $0 <config.yaml>"
    echo ""
    echo "Examples:"
    echo "  $0 outside_shutter.yaml"
    echo "  $0 inside_shutter.yaml"
    exit 1
fi

CONFIG_FILE="$1"

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file '$CONFIG_FILE' not found${NC}"
    exit 1
fi

echo -e "${GREEN}ESPHome Logs Viewer${NC}"
echo "Configuration: $CONFIG_FILE"
echo ""
echo "Connecting to device..."
echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
echo ""

# Run logs command in container
docker-compose exec esphome esphome logs "$CONFIG_FILE"
