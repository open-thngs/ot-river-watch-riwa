import esp32.espnow
import esp32.espnow show Address
import .dps368device as dps368device
import log
import .utils
import gpio

// PMK ::= espnow.Key.from-string "pmk1234567890123"
logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"
ADDRESS ::= Address #[0x8C, 0x4B, 0x14, 0x16, 0x64, 0x60]
dps368 := ?
pin := ?

main args:
  logger.debug "MACA: $get-mac-address-str"
  sync-ntp
  pin = gpio.Pin 12 --input --pull-up
  dps368 = dps368device.create
  service := espnow.Service.station --key=null
  service.add-peer ADDRESS
      --channel=1

  send-task service

send-task service/espnow.Service:
  while true:
    // 5.repeat: 
    exception := catch:
      if pin.get == 0:
        return
      bouy_pressure := dps368.pressure - 16.0
      bouy_temperature := dps368.temperature
      current-time/TimeInfo := Time.now.utc
      logger.debug "$(%.2f bouy_pressure) pA"
      logger.debug "$(%.2f bouy_temperature) °C"
      paket := "$current-time.stringify#$(%.2f bouy_pressure)#$(%.2f bouy_temperature)".to_byte_array
      // buffer := "$(%.2f bouy_pressure)".to_byte_array
      service.send paket --address=ADDRESS
      // print "Send datagram: \"$paket\""
    if exception != null:
      logger.error "Error: $exception"
    
    compute_next_start