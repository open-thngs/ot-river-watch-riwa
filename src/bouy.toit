import gpio
import i2c
import ble show *
import uuid show Uuid
import dps368
import dps368.config as cfg
import log
import ntp
import esp32 show adjust_real_time_clock
import artemis show Container
import system.storage show Bucket
import system.assets
import encoding.tison
import artemis
import .modes.bouy_default_mode show BouyDefaultPowerMode

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"

is_usb_powered := false

main args:
  handle_container_params args
  dps368 := init_dsp368
  if is_usb_powered:
    print "Running in USB powered mode"
  else:
    mode := BouyDefaultPowerMode dps368
    mode.run
    compute_next_start

init_dsp368:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  i2cdevice := bus.device dps368.I2C_ADDRESS_DEFAULT
  dps368 := dps368.DPS368 i2cdevice
  dps368.init cfg.MEASURE_RATE.TIMES_64 cfg.OVERSAMPLING_RATE.TIMES_64 cfg.MEASURE_RATE.TIMES_64 cfg.OVERSAMPLING_RATE.TIMES_64

  dps368.measureContinousPressureAndTemperature

  logger.debug "ProductId:  $dps368.productId"
  logger.debug "Config: $dps368.measure_config"
  zero := dps368.pressure
  return dps368

compute_next_start:
  adjusted_utc/TimeInfo := Time.now.utc.with --s=0 --ns=0 //get current time and sets seconds to 0
  adjusted_utc = adjusted_utc.plus --m=1 //add one minute
  sleeptime := adjusted_utc.time.ms_since_epoch - Time.now.ms_since_epoch
  logger.debug "sleeping for $sleeptime"
  Container.current.restart --delay=(Duration --ms=sleeptime)

handle_container_params args:
  print "args: $args"
  is_usb_powered = args[0] == "usb.powered=true"
