import .power_modes
import log
import artemis show Container
import dps368 show DPS368
import ..riwa_ble show RiWaBLEServer
import ringbuffer
import system.storage show Bucket
import math

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"

GRAVITY ::= 9.80665

class StationUsbPowerMode extends PowerMode:

  ble_server/RiWaBLEServer := ?
  dps368/DPS368 := ?

  storage := Bucket.open "flash:open-things.de/station"
  bouy_pressure_ring_buffer := ringbuffer.RingBuffer 10
  bouy_pressure_diff_ring_buffer := ringbuffer.RingBuffer 10

  constructor .dps368:
    logger.debug "MODE: USB powered"
    ble_server = RiWaBLEServer

  run:
    logger.debug "Starting RiWa Station"
    ble_server.start

    while true:
      bouy_pressure := ble_server.wait_and_read_pressure
      // bouy_pressure_ring_buffer.append bouy_pressure
      // logger.debug "Pressure received: $bouy_pressure"
      station_pressure := dps368.pressure
      temperature := dps368.temperature
      
      calculate_height_difference station_pressure bouy_pressure temperature
      
      // diff := station_pressure - bouy_pressure_ring_buffer.average
      // logger.debug "Pressure difference: $diff"
      // bouy_pressure_diff_ring_buffer.append diff
      // storage["pressure_difference"] = bouy_pressure_diff_ring_buffer.average

  calculate_height_difference bouy_pressure station_pressure temperature:
    logger.debug "--------------------------------------------------------"
    logger.debug "Pressure    station: $(%.2f station_pressure) pA"
    logger.debug "Pressure       bouy: $(%.2f bouy_pressure) pA"
    logger.debug "Temperature        : $(%.2f temperature) °C"
    delta_pressure := (bouy_pressure - station_pressure) - storage["pressure_difference"]
    logger.debug "Pressure difference: $(%.2f delta_pressure) pA"

    air_density := calculate_air_density temperature (station_pressure - storage["pressure_difference"])
    above_sea_level := calculate_height_above_sea_level temperature station_pressure
    logger.debug "Height sea level   : $(%.2f above_sea_level) m"
    uncertainty_pa := 0.06 * 100

    height_difference_cm := ((delta_pressure) / (air_density * GRAVITY)) * 100
    height_difference_with_uncertainty_cm := height_difference_cm + uncertainty_pa
    logger.debug "Height   difference: $(%.2f height_difference_with_uncertainty_cm) cm"

    return height_difference_with_uncertainty_cm

  calculate_height_above_sea_level temperature pressure_station:
    P0 := 1013.25
    P := pressure_station / 100

    t := temperature + 273.15
    altitude := ((math.pow (P0 / P) (1 / 5.255)) - 1) * t / 0.0065

    return altitude
    
  calculate_air_density temperature_celsius pressure_station:
    temperature_kelvin := temperature_celsius + 273.15
    molar_mass_air := 28.97
    molar_mass_kg_per_mol := molar_mass_air / 1000

    air_density := (pressure_station * molar_mass_kg_per_mol) / (8.314 * temperature_kelvin)
    logger.debug "Density air sea level: $(%.2f air_density) kg/m^3"
    return air_density