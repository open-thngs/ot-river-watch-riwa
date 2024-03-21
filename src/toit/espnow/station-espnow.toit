import esp32.espnow
import esp32.espnow show Address
import .dps368device as dps368device
import log
import .utils
import .meteorology show MeteorologicalData
import gpio

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 0

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"
dps368 := ?
pin := ?

r := gpio.Pin 5 --output=true 
g := gpio.Pin 6 --output=true 
b := gpio.Pin 7 --output=true

main args:
  show-green

  logger.debug "MACA: $get-mac-address-str"
  sync-ntp
  pin = gpio.Pin 2 --input --pull-up
  dps368 = dps368device.create
  service := espnow.Service.station --key=null
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS 
    --channel=CHANNEL

  receive-task service

receive-task service/espnow.Service:
  while true:
    if pin.get == 0:
      return
    show-red
    bouy-pressure := 0.0
    bouy-temperature := 0.0
    m-time := Time.now.utc
    // timeout := catch: with-timeout (Duration --ms=5000):
    print "Waiting for data"
    datagram := service.receive
    logger.debug "Received data $datagram.stringify"
    data-split := datagram.data.to-string.split "#"
    m-time = (Time.parse data-split[0]).utc
    bouy-pressure = float.parse data-split[1]
    bouy-temperature = float.parse data-split[2]
    
    // if timeout:
    //   logger.debug "Timeout"
    //   compute-next-start
    //   continue
   
    station-pressure := dps368.pressure
    
    meteo-data := MeteorologicalData bouy-pressure station-pressure dps368.temperature
    meteo-data.dump
    // sleep --ms=250
    led-off
    // logger.debug "Time: $(%02d m-time.h):$(%02d m-time.m):$(%02d m-time.s) $(%.2f bouy-pressure) $(%.2f bouy-temperature)"
    compute-next-start

show-green:
  r.set 1
  g.set 0
  b.set 1

show-red:
  r.set 0
  g.set 1
  b.set 1

show-blue:
  r.set 1
  g.set 1
  b.set 0

led-off:
  r.set 1
  g.set 1
  b.set 1