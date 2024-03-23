import esp32.espnow
import esp32.espnow show Address
import log
import gpio
import .utils
import .rgb-led show RGBLED

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 2

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"
led := RGBLED

main args:
  led.blue

  logger.debug "MACA: $get-mac-address-str"
  logger.debug "Start Bouy"
  service := espnow.Service.station --key=null --channel=CHANNEL
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS

  paket := "test-data".to_byte_array
  logger.debug "Send datagram: \"$paket\""
  service.send paket --address=ADDRESS