import esp32.espnow
import esp32.espnow show Address
import log
import gpio
import .utils
import .rgb-led show RGBLED

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 2

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"
led := RGBLED

main args:
  led.green

  logger.debug "MACA: $get-mac-address-str"
  logger.debug "Start Station"
  service := espnow.Service.station --key=null --channel=CHANNEL
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS

  while true:
    print "Waiting for data"
    datagram := service.receive
    logger.debug "Received data $datagram.stringify"