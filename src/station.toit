import gpio
import i2c
import ble show *
import uuid show Uuid
import dps368
import dps368.config as cfg
import log
import artemis show Container
import monitor show Semaphore
import binary
import system.assets
import encoding.tison
import artemis
import system.storage show Bucket
import ringbuffer
import .modes.station_default_mode
import .modes.station_usb_mode

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"

is_usb_powered := false

main args:
  handle_container_params args
  dps368 := create_dps368
  if is_usb_powered:
    mode := StationUsbPowerMode dps368
    mode.run
  else:
    mode := StationDefaultPowerMode dps368
    mode.run
    compute_next_start

create_dps368 -> dps368.DPS368:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  device := bus.device dps368.I2C_ADDRESS_DEFAULT
  dps368 := dps368.DPS368 device
  dps368.init cfg.MEASURE_RATE.TIMES_64 cfg.OVERSAMPLING_RATE.TIMES_64 cfg.MEASURE_RATE.TIMES_64 cfg.OVERSAMPLING_RATE.TIMES_64

  dps368.measureContinousPressureAndTemperature

  logger.debug "ProductId:  $dps368.productId"
  logger.debug "Config: $dps368.measure_config"
  zero := dps368.pressure
  return dps368

compute_next_start:
  adjusted_utc/TimeInfo := Time.now.utc.with --s=0 --ns=0
  adjusted_utc = adjusted_utc.plus --s=10
  sleeptime := adjusted_utc.time.ms_since_epoch - Time.now.ms_since_epoch
  logger.debug "sleeping for $sleeptime"
  Container.current.restart --delay=(Duration --ms=sleeptime)

handle_container_params args:
  print "args: $args"
  is_usb_powered = args[0] == "usb.powered=true"
