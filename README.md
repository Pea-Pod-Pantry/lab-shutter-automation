# ESPHome Shed Door Opener

A dual-node ESPHome system for automating a shed door, featuring secure inter-unit communication, RFID access, keypad entry, and motor control.

## 🏗 System Architecture

The system consists of two ESP32 units communicating via a wired UART link:

1.  **Outside Unit**: 
    *   **Role**: User Interface (Keypad, RFID, Status LEDs)
    *   **Hardware**: ESP32-DevKit V1
    *   **Function**: Captures user input and sends authenticated commands/data to the Inside Unit.
    *   **Security**: Does NOT store valid credentials. Sends raw input to the secure Inside Unit.

2.  **Inside Unit**:
    *   **Role**: Logic & Actuation (Relays, Sensors, Auth Verification)
    *   **Hardware**: WT32-ETH01
    *   **Function**: Verifies PIN/Tags, controls motor relays, and manages the door state.
    *   **Security**: Stores valid credentials (hashed/secrets) and executes critical logic.

## 🔌 Hardware Connections

### Outside Unit (ESP32-DevKit)

| Component | Pin | Notes |
| :--- | :--- | :--- |
| **UART TX** | **GPIO17** | Connects to Inside Unit RX |
| **UART RX** | **GPIO16** | Connects to Inside Unit TX |
| **RFID SDA (CS)** | GPIO5 | RC522 SPI Chip Select |
| **RFID SCK** | GPIO18 | RC522 SPI Clock |
| **RFID MOSI** | GPIO23 | RC522 SPI MOSI |
| **RFID MISO** | GPIO19 | RC522 SPI MISO |
| **RFID RST** | GPIO22 | RC522 Reset |
| **Keypad Rows** | GPIO32, 33, 25, 26 | 4x4 Matrix Keypad |
| **Keypad Cols** | GPIO27, 14, 4, 13 | 4x4 Matrix Keypad |

### Inside Unit (WT32-ETH01)

| Component | Pin | Notes |
| :--- | :--- | :--- |
| **UART TX** | **GPIO17** | Connects to Outside Unit RX |
| **UART RX** | **GPIO5** | Connects to Outside Unit TX |
| **Motor UP Relay** | GPIO4 | Controls Up movement (Pulse 250ms) |
| **Motor DOWN Relay** | GPIO2 | Controls Down movement (Pulse 250ms) |
| **Motor STOP Relay** | **GPIO32** | Controls Stop mechanism (Pulse 250ms) |
| **Manual UP Btn** | GPIO15 | Physical button (Input Pullup) |
| **Manual DOWN Btn** | GPIO14 | Physical button (Input Pullup) |
| **Manual STOP Btn** | GPIO12 | Physical button (Input Pullup) |

> [!IMPORTANT]
> **Common Ground**: Ensure both ESP32 units share a common Ground (GND) connection for reliable UART communication.

## 🚀 Quick Start

### 1. Configuration to `secrets.yaml`

Create a `secrets.yaml` file in the project root with your WiFi credentials:

```yaml
wifi_ssid: "Your_SSID"
wifi_password: "Your_Password"
```

> [!NOTE]
> **PIN & Tag Configuration**: You no longer need to hardcode `valid_pin` or `valid_tag` in `secrets.yaml`. These are now managed dynamically via the Web Interface.

### 2. Initial Setup & Global PIN

On the very first boot, the Inside Unit will generate a **Random 6-digit Master PIN**.

1.  **Access Web Interface**: Go to `http://<device_ip>` in your browser.
2.  **Find the Master PIN**: Look for the **"Master PIN Display"** sensor value on the dashboard.
    *   *(Backup)*: You can also find it in the USB logs: `[setup] GENERATED NEW MASTER PIN: XXXXXX`.
3.  **Unlock Admin Mode**: Enter the displayed Master PIN into the "Admin PIN Input" field.
4.  **Set User PIN**: Enter your desired 4-digit User PIN (for daily use) and it will be saved.
5.  **Register Tags**:
    *   Click **Unlock Admin Mode** (if not already unlocked).
    *   Click **Toggle Card Registration** to enable learning mode.
    *   Scan your NFC tags at the Outside Unit. Watch the logs/web UI for "New TAG Registered".
    *   Click **Toggle Card Registration** again to save and exit learning mode.

### 2. Flash the Devices

You can flash via USB or OTA (if already running ESPHome).

**Outside Unit:**
```bash
esphome run outside_shutter.yaml
```

**Inside Unit:**
```bash
esphome run inside_shutter.yaml
```

### 3. Usage

*   **Unlock via PIN**: Enter the PIN on the keypad followed by `#` (e.g., `1234#`).
*   **Unlock via RFID**: Scan a registered RFID tag.
*   **Control Door**:
    *   **A**: Open (UP)
    *   **B**: Close (DOWN)
    *   **C**: Stop
    *   **D**: (Reserved)
*   **Manual Override**: Use the physical buttons connected to the Inside Unit.

## 🐛 Troubleshooting

*   **No Communication**: Check the log output of both units. If you see `>>>` (TX) but no `<<<` (RX), check your wiring (TX->RX, RX->TX) and ensure a common ground.
*   **Invalid PIN/Tag**: Check the logs on the **Inside Unit**. It will print `Invalid PIN: ...` or `Invalid TAG: ...`. Update `secrets.yaml` with the correct values.

## 📁 Project Structure

*   `inside_shutter.yaml`: Configuration for the main controller.
*   `outside_shutter.yaml`: Configuration for the keypad/RFID panel.
*   `components/uart_reader`: Custom C++ component for reliable UART message parsing.
