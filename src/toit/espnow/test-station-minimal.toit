import esp32.espnow
import esp32.espnow show Address
import log
import gpio
import .utils

ADDRESS ::= Address #[0x30, 0x30, 0xF9, 0x79, 0x1A, 0xE4]
CHANNEL ::= 0

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="station"

main args:
  r := gpio.Pin 5 --output=true 
  g := gpio.Pin 6 --output=true 
  b := gpio.Pin 7 --output=true
  r.set 1
  g.set 0
  b.set 1

  logger.debug "MACA: $get-mac-address-str"
  logger.debug "Start Station"
  service := espnow.Service.station --key=null
  logger.debug "Add peer: $ADDRESS on channel $CHANNEL"
  service.add-peer ADDRESS
    --channel=CHANNEL

  while true:
    print "Waiting for data"
    datagram := service.receive
    logger.debug "Received data $datagram.stringify"