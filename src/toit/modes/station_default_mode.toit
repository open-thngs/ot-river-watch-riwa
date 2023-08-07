import .power_modes
import log
import ..riwa_ble show RiWaBLEServer
import system.storage show Bucket

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"

class StationDefaultPowerMode extends PowerMode:

  storage := Bucket.open "flash:open-things.de/station"
  ble_server/RiWaBLEServer := ?
  dps368 := ?

  constructor .dps368:
    logger.debug "MODE: Battery powered"
    ble_server = RiWaBLEServer

  run:
    logger.debug "Starting RiWa Station"
    ble_server.start
    
    station_pressure := dps368.pressure
    logger.debug "Pressure station: $station_pressure pA"
    bouy_pressure := ble_server.wait_and_read_pressure 3000
    ble_server.stop
    logger.debug "Pressure received: $bouy_pressure pA"
    pressure_difference := station_pressure - (bouy_pressure + storage["pressure_difference"])
    logger.debug "Pressure difference: $pressure_difference"
    height_in_cm := calculate_height station_pressure bouy_pressure
    logger.debug "Height: $height_in_cm cm"
    
  calculate_height station_pressure bouy_pressure:
    relative_accuracy_Pa := 0.06 * 100
    height_difference_cm := (bouy_pressure - station_pressure) * relative_accuracy_Pa
    return height_difference_cm
