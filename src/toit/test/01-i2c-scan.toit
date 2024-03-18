import i2c
import gpio

main:
  bus := i2c.Bus
    --sda=gpio.Pin 18
    --scl=gpio.Pin 17

  devices := bus.scan
  print devices

  assert: devices.size == 2