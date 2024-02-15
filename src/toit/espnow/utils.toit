import artemis show Container
import log
import esp32
import math
import ntp
import esp32 show adjust-real-time-clock

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="utils"

get_mac_address_:
  #primitive.esp32.get_mac_address

get_mac_address_str:
  mac := get_mac_address_
  macstr := ""
  mac.do: | element |
    macstr += "$(%x element)"

  return macstr.to_ascii_upper

compute_next_start:
  current-time/TimeInfo := Time.now.utc
  logger.debug "Time: $(%02d current-time.h):$(%02d current-time.m):$(%02d current-time.s)"
  current-second := current-time.s
  next-tenth-seconds := ((current-second % 100) - (current-second % 10)) + 10
  logger.debug "current-second: $current-second, next-tenth-seconds: $next-tenth-seconds"
  next-time/TimeInfo := Time.now.utc.with --s=next-tenth-seconds --ns=0
  remaining-ms := next-time.time.ms-since-epoch - current-time.time.ms-since-epoch
  logger.debug "sleeping for $remaining-ms"
  sleep --ms=remaining-ms
  // esp32.deep-sleep (Duration --ms=remaining-ms)
  // Container.current.restart --delay=(Duration --ms=sleeptime)

sync-ntp:
  now := Time.now
  if now < (Time.parse "2022-01-10T00:00:00Z"):
    result ::= ntp.synchronize
    if result:
      adjust-real-time-clock result.adjustment
      print "Set time to $Time.now by adjusting $result.adjustment"
    else:
      print "ntp: synchronization request failed"
  else:
    print "We already know the time is $now"