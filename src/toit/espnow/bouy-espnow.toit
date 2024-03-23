import esp32.espnow
import esp32.espnow show Address
import .dps368device as dps368device
import .rgb-led show RGBLED
import log
import .utils
import gpio
import system
import .rtc show RTC
import i2c

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 5

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"
dps368 := ?
rtc := ?
rtc-interrupt-pin := ?
btn-interrupt-pin := ?
led := ?
service := ?

main args:
  logger.debug "MACA: $get-mac-address-str"
  led = RGBLED
  led.green

  bus := i2c.Bus
    --sda=gpio.Pin 18
    --scl=gpio.Pin 17

  rtc-interrupt-pin = gpio.Pin 1 --input --pull-up=true
  btn-interrupt-pin = gpio.Pin 2 --input
  rtc = RTC bus
  dps368 = dps368device.create bus

  // task::button-watch
  task::rtc-irq-watch
  
  service = espnow.Service.station --key=null --channel=CHANNEL
  logger.debug "Add peer: $espnow.BROADCAST-ADDRESS on channel $CHANNEL"
  service.add-peer espnow.BROADCAST-ADDRESS

  send-data

send-data:
  led.red
  paket := create-paket
  send-paket paket
  led.green
  rtc.set-alarm
  led.off

create-paket:
  bouy_pressure := dps368.pressure
  bouy_temperature := dps368.temperature
  current-time/TimeInfo := rtc.now
  logger.debug "$(%.2f bouy_pressure) pA"
  logger.debug "$(%.2f bouy_temperature) °C"
  return "$current-time.stringify#$(%.2f bouy_pressure)#$(%.2f bouy_temperature)".to_byte_array

send-paket paket:
  logger.debug "Send datagram: \"$paket\" (size: $paket.size)"
  exception := catch --trace:
    service.send paket --address=espnow.BROADCAST-ADDRESS

  if exception: logger.error "Failed to send datagram: $exception"

// button-watch:
//   while true:
//     btn-interrupt-pin.wait-for 0
//     logger.debug "Button pressed"
//     btn-interrupt-pin.wait-for 1

rtc-irq-watch:
  while true:
    rtc-interrupt-pin.wait-for 0
    logger.debug "Countdown reached"
    send-data
    rtc-interrupt-pin.wait-for 1