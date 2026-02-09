#pragma once

#include "esphome.h"
#include "esphome/components/text_sensor/text_sensor.h"
#include "esphome/components/uart/uart.h"

namespace esphome {
namespace uart_reader {

class UartReader : public Component, public uart::UARTDevice {
public:
  text_sensor::TextSensor *text_sensor;

  UartReader(uart::UARTComponent *parent, text_sensor::TextSensor *text_sensor)
      : uart::UARTDevice(parent), text_sensor(text_sensor) {}

  void setup() override {
    ESP_LOGD("uart_reader", "Setup UartReader Component");
  }

  void loop() override {
    const int max_line_length = 80;
    static char buffer[max_line_length];

    while (available()) {
      int c = read();
      // ESP_LOGD("uart_reader_raw", "Char: %d", c); // Debug only
      if (readline(c, buffer, max_line_length) > 0) {
        ESP_LOGD("uart_reader", "Received Line: %s", buffer);
        text_sensor->publish_state(buffer);
      }
    }
  }

  int readline(int readch, char *buffer, int len) {
    static int pos = 0;
    int rpos;

    if (readch > 0) {
      switch (readch) {
      case '\n':       // Return on NL
      case '\r':       // Return on CR
        if (pos > 0) { // Only return if we have content
          rpos = pos;
          pos = 0;
          return rpos;
        }
        return -1;
      default:
        if (pos < len - 1) {
          buffer[pos++] = readch;
          buffer[pos] = 0;
        }
      }
    }
    return -1;
  }
};

} // namespace uart_reader
} // namespace esphome
