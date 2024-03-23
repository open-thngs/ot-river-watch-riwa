import esp32.espnow
import esp32.espnow show Address
import .dps368device as dps368device
import .rgb-led show RGBLED
import log
import .utils
import .meteorology show MeteorologicalData
import gpio
import .rtc show RTC
import i2c

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 5

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"
dps368 := ?
rtc := ?
rtc-interrupt-pin := ?
btn-interrupt-pin := ?
led := ?
service := ?

main args:
  led = RGBLED
  led.green

  logger.debug "MACA: $get-mac-address-str"
  bus := i2c.Bus
    --sda=gpio.Pin 18
    --scl=gpio.Pin 17

  rtc-interrupt-pin = gpio.Pin 1 --input --pull-up=true
  btn-interrupt-pin = gpio.Pin 2 --input
  rtc = RTC bus
  dps368 = dps368device.create bus

  service = espnow.Service.station --key=null --channel=CHANNEL
  logger.debug "Add peer: $espnow.BROADCAST-ADDRESS on channel $CHANNEL"
  service.add-peer espnow.BROADCAST-ADDRESS 

  task::rtc-irq-watch

  start-receiver-service

start-receiver-service:
  led.red
  bouy-pressure := 0.0
  bouy-temperature := 0.0
  m-time := Time.now.utc

  print "Waiting for data"
  timeout := catch: with-timeout (Duration --ms=5000):
    datagram := service.receive
    logger.debug "Received data $datagram.stringify"
    data-split := datagram.data.to-string.split "#"
    m-time = (Time.parse data-split[0]).utc
    bouy-pressure = float.parse data-split[1]
    bouy-temperature = float.parse data-split[2]
    
    station-pressure := dps368.pressure
    
    meteo-data := MeteorologicalData bouy-pressure station-pressure dps368.temperature
    meteo-data.dump

  if timeout:
    logger.debug "ERROR: Timeout reached"
  
  rtc.set-alarm
  led.off

rtc-irq-watch:
  while true:
    rtc-interrupt-pin.wait-for 0
    logger.debug "Countdown reached"
    start-receiver-service
    rtc-interrupt-pin.wait-for 1