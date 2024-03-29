import .power_modes
import log
import ..riwa_ble show RiWaBLEClient

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"

class BouyUsbPowerMode extends PowerMode:

  dps368 := ?
  ble_client := ?

  constructor .dps368:
    logger.debug "MODE: USB powered"
    ble_client = RiWaBLEClient

  run:
    logger.debug "Starting RiWa Bouy"
    ble_client.connect 60
    
    while true:
      pressure-total := 0.0
      10.repeat:
        pressure-total += dps368.pressure
        sleep --ms=20
      bouy_pressure := pressure-total / 10
      bouy_temperature := dps368.temperature
      logger.debug "$(%.2f bouy_pressure) pA"
      logger.debug "$(%.2f bouy_temperature) °C"
      ble_client.write_pressure "$(%.2f dps368.pressure)".to_byte_array
      sleep --ms=2000
  