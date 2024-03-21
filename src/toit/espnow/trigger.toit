import log
import gpio
import .rgb-led

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="bouy"

led := RGBLED

main:
  print Time.monotonic-us
  led.set-color 0 255 0
  sleep --ms=1000
  led.set-color 0 0 0