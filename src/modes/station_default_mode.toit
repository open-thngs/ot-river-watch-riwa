import .power_modes
import log
import ..riwa_ble_server show RiWaBLEServer

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"

class StationDefaultPowerMode extends PowerMode:

  ble_server/RiWaBLEServer := ?
  dps368 := ?

  constructor .dps368:
    logger.debug "MODE: Battery powered"
    ble_server = RiWaBLEServer

  run:
    logger.debug "Starting RiWa Station"
    ble_server.start
    
    station_pressure := dps368.pressure
    bouy_pressure := ble_server.wait_and_read_pressure 3000
    logger.debug "Pressure received: $bouy_pressure"
