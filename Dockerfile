FROM esphome/esphome:latest

# Install additional tools for development
RUN apt-get update && apt-get install -y \
    socat \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /config

# Expose ESPHome dashboard port
EXPOSE 6052

# Default command runs the dashboard
CMD ["dashboard", "/config"]
