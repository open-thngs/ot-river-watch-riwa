import .power_modes
import log
import artemis show Container
import dps368 show DPS368
import ..riwa_ble_server show RiWaBLEServer

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"


class StationUsbPowerMode extends PowerMode:

  ble_server/RiWaBLEServer := ?
  dps368/DPS368 := ?

  constructor .dps368:
    logger.debug "MODE: USB powered"
    ble_server = RiWaBLEServer

  run:
    logger.debug "Starting RiWa Station"
    ble_server.start

    while true:
      bouy_pressure := ble_server.wait_and_read_pressure
      logger.debug "Pressure received: $bouy_pressure"
      station_pressure := dps368.pressure
      
      diff := station_pressure - bouy_pressure
      logger.debug "Pressure difference: $diff"
    
