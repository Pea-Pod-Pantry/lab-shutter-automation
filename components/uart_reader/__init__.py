import esphome.codegen as cg
import esphome.config_validation as cv
from esphome.components import uart, text_sensor
from esphome.const import CONF_ID, CONF_LIBRARIES

DEPENDENCIES = ['uart']

uart_reader_ns = cg.esphome_ns.namespace('uart_reader')
UartReader = uart_reader_ns.class_('UartReader', cg.Component, uart.UARTDevice)

CONFIG_SCHEMA = cv.Schema({
    cv.GenerateID(): cv.declare_id(UartReader),
    cv.Required('uart_id'): cv.use_id(uart.UARTComponent), 
    cv.Required('text_sensor_id'): cv.use_id(text_sensor.TextSensor),
}).extend(cv.COMPONENT_SCHEMA).extend(uart.UART_DEVICE_SCHEMA)

def to_code(config):
    uart_component = yield cg.get_variable(config['uart_id'])
    text_sensor_component = yield cg.get_variable(config['text_sensor_id'])
    var = cg.new_Pvariable(config[CONF_ID], uart_component, text_sensor_component)
    yield cg.register_component(var, config)
    yield uart.register_uart_device(var, config)
