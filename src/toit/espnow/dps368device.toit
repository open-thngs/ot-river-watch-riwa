import gpio
import i2c
import dps368
import dps368.config as cfg
import log

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"

create:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  i2cdevice := bus.device dps368.I2C_ADDRESS_DEFAULT
  dps368 := dps368.DPS368 i2cdevice
  dps368.init cfg.MEASURE_RATE.TIMES_4 cfg.OVERSAMPLING_RATE.TIMES_64 cfg.MEASURE_RATE.TIMES_4 cfg.OVERSAMPLING_RATE.TIMES_64

  dps368.measureContinousPressureAndTemperature

  logger.debug "ProductId:  $dps368.productId"
  logger.debug "Config: $dps368.measure_config"
  zero := dps368.pressure
  return dps368