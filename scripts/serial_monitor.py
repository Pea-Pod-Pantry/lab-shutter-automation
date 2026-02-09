#!/usr/bin/env python3
import serial
import sys

# Configure serial port
port = '/dev/cu.usbserial-0001'
baud_rate = 115200

try:
    print(f"Opening serial port {port} at {baud_rate} baud...")
    ser = serial.Serial(port, baud_rate, timeout=1)
    print("Connected! Reading logs (Press Ctrl+C to exit):\n")
    print("=" * 80)
    
    while True:
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8', errors='ignore').rstrip()
            if line:
                print(line)
                sys.stdout.flush()
                
except KeyboardInterrupt:
    print("\n\nExiting...")
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'ser' in locals() and ser.is_open:
        ser.close()
