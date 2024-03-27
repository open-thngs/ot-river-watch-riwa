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
import esp32

// ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x19, 0xC8] 
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
  led.set-brightness 10
  led.green

  bus := i2c.Bus
    --sda=gpio.Pin 18
    --scl=gpio.Pin 17

  rtc-interrupt-pin = gpio.Pin 1 --input --pull-up=true
  // btn-interrupt-pin = gpio.Pin 2 --input
  rtc = RTC bus
  dps368 = dps368device.create bus

  // task::button-watch
  // task::rtc-irq-watch
  
  service = espnow.Service.station --key=null --channel=CHANNEL
  // service = espnow.Service.station --key=null 
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS 

  send-data

send-data:
  while true:
    led.green
    paket := create-paket
    send-paket paket
    // next-time := rtc.compute-next-boot-time-min
    // rtc.set-alarm next-time
    // led.red
    sleep --ms=2000

  // esp32.enable-external-wakeup (1 << 1) false
  // esp32.deep-sleep (Duration --m=1)

create-paket:
  dps368.measurePressureOnce
  bouy_pressure := dps368.pressure
  // bouy_temperature := dps368.temperature

  dps368.measureTemperatureOnce
  bouy_temperature := dps368.temperature
  current-time/TimeInfo := rtc.now
  logger.debug "$(%.2f bouy_pressure) pA"
  logger.debug "$(%.2f bouy_temperature) °C"
  return "$current-time.stringify#$(%.2f bouy_pressure)#$(%.2f bouy-temperature)".to_byte_array

send-paket paket:
  logger.debug "Send datagram: \"$paket\" (size: $paket.size)"
  3.repeat:
    exception := catch --trace:
      service.send paket --address=ADDRESS
      return

    if exception: 
      led.red
      logger.error "Failed to send datagram: $exception"
    sleep --ms=100

// button-watch:
//   while true:
//     btn-interrupt-pin.wait-for 0
//     logger.debug "Button pressed"
//     btn-interrupt-pin.wait-for 1

rtc-irq-watch:
  while true:
    rtc-interrupt-pin.wait-for 0
    // logger.debug "Countdown reached"
    send-data
    rtc-interrupt-pin.wait-for 1