import log
import math

GRAVITY ::= 9.80665
UNCERTAINTY_PA ::= 0.06 * 100
SEA_LEVEL_PRESSURE_PA ::= 1013.25 //the standard atmospheric pressure at sea level
HEAT_RATIO ::= 1 / 5.255          //the reciprocal of the adiabatic index (or specific heat ratio) for dry air at room temperature.
LAPS_RATE ::= 0.0065              //the standard lapse rate, which is the rate at which temperature decreases with an increase in altitude in the troposphere.

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="pressure-math"

class MeteorologicalData:
  bouy-pressure := ?
  bouy-temperature := ?
  station-pressure := ?
  temperature := ?
  air-density := 0
  above-sea-level := 0
  delta-pressure := 0
  height-difference-cm := 0
  height-difference-with-uncertainty-cm := 0

  constructor .bouy-pressure .bouy-temperature .station-pressure .temperature:
    air-density = calculate_air_density temperature station_pressure
    above-sea-level = calculate_height_above_sea_level temperature station_pressure
    delta-pressure = (bouy_pressure - station_pressure)
    height-difference-cm = ((delta_pressure) / (air_density * GRAVITY)) * 100
    height-difference-with-uncertainty-cm = height_difference_cm + UNCERTAINTY_PA

  calculate_air_density temperature-celsius pressure-station:
    // formula for air density: ρ = P / (R * T)
    temperature_kelvin := temperature_celsius + 273.15
    molar_mass_air := 28.97
    molar_mass_kg_per_mol := molar_mass_air / 1000
    return (pressure_station * molar_mass_kg_per_mol) / (8.314 * temperature_kelvin)

  calculate_height_above_sea_level temperature pressure_station:
    //FORMULA: h = ((P0 / P)^(1 / a) - 1) * (T / L)
    P := pressure_station / 100
    t := temperature + 273.15
    altitude := ((math.pow (SEA_LEVEL_PRESSURE_PA / P) HEAT_RATIO) - 1) * t / LAPS_RATE
    return altitude

  dump:
    logger.debug " "
    logger.debug "--------------------------------------------------------"
    logger.debug "bouy-pressure:    $(%.2f bouy-pressure) Pa"
    logger.debug "station-pressure: $(%.2f station-pressure) Pa"
    logger.debug "temperature:      $(%.2f temperature)°C"
    // logger.debug "air-density: $air-density"
    logger.debug "above-sea-level:  $(%.2f above-sea-level) m"
    // logger.debug "delta-pressure: $delta-pressure"
    logger.debug "height-difference-cm: $(%.2f height-difference-cm) cm"
    // logger.debug "height-difference-with-uncertainty-cm: $height-difference-with-uncertainty-cm"

  dump-simple:
    logger.debug "Bouy:    $(%.2f bouy-pressure) Pa     $(%.2f bouy-temperature)°C"
    logger.debug "Station: $(%.2f station-pressure) Pa  $(%.2f temperature)°C"
    logger.debug "#####################################"
    logger.debug "# Height: $(%.2f height-difference-cm) cm"
    logger.debug "#####################################"


    