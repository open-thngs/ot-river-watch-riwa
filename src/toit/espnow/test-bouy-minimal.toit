import esp32.espnow
import esp32.espnow show Address
import log
import gpio
import .utils

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 0

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"

main args:
  r := gpio.Pin 5 --output=true 
  g := gpio.Pin 6 --output=true 
  b := gpio.Pin 7 --output=true
  r.set 1
  g.set 1
  b.set 0

  logger.debug "MACA: $get-mac-address-str"
  logger.debug "Start ESP-NOW"
  service := espnow.Service.station --key=null
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS
      --channel=CHANNEL

  paket := "test-data".to_byte_array
  logger.debug "Send datagram: \"$paket\""
  service.send paket --address=ADDRESS