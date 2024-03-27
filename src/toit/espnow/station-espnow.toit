import esp32.espnow
import esp32.espnow show Address
import esp32
import .dps368device as dps368device
import .rgb-led show RGBLED
import log
import .utils
import .meteorology show MeteorologicalData
import gpio
import .rtc show RTC
import i2c

// ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x19, 0xC8]
CHANNEL ::= 5

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"
dps368 := ?
rtc := ?
rtc-interrupt-pin := ?
btn-interrupt-pin := ?
led := ?
service := ?
data-log := []

station-pressure := 0.0
station-temperature := 0.0

main args:
  logger.debug "Reset reason: $esp32.reset-reason (not external gpio)"

  led = RGBLED
  led.green

  logger.debug "MACA: $get-mac-address-str"
  bus := i2c.Bus
    --sda=gpio.Pin 18
    --scl=gpio.Pin 17

  // rtc-interrupt-pin = gpio.Pin 1 --input --pull-up=true
  // btn-interrupt-pin = gpio.Pin 2 --input
  rtc = RTC bus
  dps368 = dps368device.create bus

  dps368.measurePressureOnce
  station-pressure = dps368.pressure
  // station-temperature = dps368.temperature
  print "Station pressure: $station-pressure"

  service = espnow.Service.station --key=null --channel=CHANNEL
  // service = espnow.Service.station --key=null 
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS

  // task::rtc-irq-watch
  
  start-receiver-service
  bus.close

start-receiver-service:
  bouy-pressure := 0.0
  bouy-temperature := 0.0
  m-time := Time.now.utc

  while true:
    print "Waiting for data"
    led.yellow
    // timeout := catch: with-timeout (Duration --ms=1500):
    while true:
      datagram := service.receive
      led.green
      current-time := rtc.now
      data-split := datagram.data.to-string.split "#"
      m-time = (Time.parse data-split[0]).utc
      bouy-pressure = (float.parse data-split[1])
      bouy-temperature = float.parse data-split[2]

      dps368.measurePressureOnce
      station-pressure = dps368.pressure

      dps368.measureTemperatureOnce
      station-temperature = dps368.temperature
      
      meteo-data := MeteorologicalData bouy-pressure bouy-temperature station-pressure station-temperature
      meteo-data.dump-simple
      
      // data-log.add "$current-time,$(%2f meteo-data.station-pressure),$(%2f station-temperature),$(%2f meteo-data.bouy-pressure),$(%2f bouy-temperature),$(%2f meteo-data.height-difference-cm)"

    // if timeout:
    //   logger.debug "ERROR: Timeout reached"
  
  // next-time := rtc.compute-next-boot-time-min
  // rtc.set-alarm next-time
  // led.off

  // esp32.enable-external-wakeup (1 << 1) false
  // esp32.deep-sleep (Duration --m=1)

  // data-log.do:
  //   logger.debug it

rtc-irq-watch:
  while true:
    rtc-interrupt-pin.wait-for 0
    // logger.debug "Countdown reached"
    start-receiver-service
    rtc-interrupt-pin.wait-for 1