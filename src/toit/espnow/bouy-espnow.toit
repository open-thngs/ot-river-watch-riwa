import esp32.espnow
import esp32.espnow show Address
import .dps368device as dps368device
import .rgb-led show RGBLED
import log
import .utils
import gpio
import system

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 0

// PMK ::= espnow.Key.from-string "pmk1234567890123"
logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"

dps368 := ?
pin := ?
led := ?

main args:
  logger.debug "MACA: $get-mac-address-str"
  led = RGBLED
  sync-ntp
  pin = gpio.Pin 2 --input
  task::button-watch
  dps368 = dps368device.create
  service := espnow.Service.station --key=null
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS
      --channel=CHANNEL

  while true:
    // 5.repeat: 
      // if pin.get == 0:
      //   return
    led.green
    bouy_pressure := dps368.pressure
    bouy_temperature := dps368.temperature
    current-time/TimeInfo := Time.now.utc
    logger.debug "$(%.2f bouy_pressure) pA"
    logger.debug "$(%.2f bouy_temperature) °C"
    paket := "$current-time.stringify#$(%.2f bouy_pressure)#$(%.2f bouy_temperature)".to_byte_array
    // buffer := "$(%.2f bouy_pressure)".to_byte_array
    led.red
    logger.debug "Send datagram: \"$paket\" (size: $paket.size)"
    service.send paket --address=ADDRESS
    sleep --ms=250
    led.green
      
    // sleep --ms=10000
    compute_next_start

button-watch:
  while true:
    pin.wait-for 0
    logger.debug "Button pressed"
    pin.wait-for 1