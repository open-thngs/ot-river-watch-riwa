import esp32.espnow
import esp32.espnow show Address
import .dps368device as dps368device
import log
import .utils
import .meteorology show MeteorologicalData
import gpio

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"
dps368 := ?
pin := ?

main args:
  logger.debug "MACA: $get-mac-address-str"
  sync-ntp
  pin = gpio.Pin 12 --input --pull-up
  dps368 = dps368device.create
  service := espnow.Service.station --key=null
  service.add-peer (Address #[0x8C, 0x4B, 0x14, 0x16, 0x6A, 0x6C]) --channel=1
  receive-task service

receive-task service/espnow.Service:
  while true:
    if pin.get == 0:
      return
    bouy-pressure := 0.0
    bouy-temperature := 0.0
    m-time := Time.now.utc
    timeout := catch --trace: with-timeout (Duration --ms=5000):
      datagram := service.receive
      data-split := datagram.data.to-string.split "#"
      m-time = (Time.parse data-split[0]).utc
      bouy-pressure = float.parse data-split[1]
      bouy-temperature = float.parse data-split[2]
    if timeout:
      logger.debug "Timeout"
      compute-next-start
      continue
   
    station-pressure := dps368.pressure
    
    meteo-data := MeteorologicalData bouy-pressure station-pressure dps368.temperature
    meteo-data.dump
    logger.debug "Time: $(%02d m-time.h):$(%02d m-time.m):$(%02d m-time.s) $(%.2f bouy-pressure) $(%.2f bouy-temperature)"
    compute-next-start