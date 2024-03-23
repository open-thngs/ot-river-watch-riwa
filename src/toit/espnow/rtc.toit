import rv-3028-c7
import rv-3028-c7.alarm show Alarm
import ntp
import esp32 show adjust-real-time-clock
import log 
import gpio

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="time-keeper"

class RTC:

  rtc/rv-3028-c7.RV-3028-C7 := ?

  constructor bus:
    device := bus.device rv-3028-c7.I2C_ADDRESS
    rtc = rv-3028-c7.RV-3028-C7 device.registers
    sync-ntp

  sync-ntp:
    now := rtc.now
    if now < (Time.parse "2022-01-10T00:00:00Z"):
      3.repeat: | count |
        result ::= ntp.synchronize
        if result:
          adjust-real-time-clock result.adjustment
          logger.debug "Set time to $Time.now by adjusting $result.adjustment"
          rtc.set Time.now
        else:
          print "ntp: synchronization request #$count failed, retrying"
          sleep --ms=500
    else:
      print "We already know the time is $now"

  now:
    return rtc.now.local

  compute-next-boot-time:
    current-time/TimeInfo := rtc.now.local
    logger.debug "Current time: $current-time"
    current-second := current-time.s
    next-tenth-seconds := ((current-second % 100) - (current-second % 10)) + 10
    logger.debug "current-second: $current-second, next-tenth-seconds: $next-tenth-seconds"
    next-time/TimeInfo := Time.now.utc.with --s=next-tenth-seconds --ns=0
    remaining-ms := next-time.time.ms-since-epoch - current-time.time.ms-since-epoch
    logger.debug "computed time to sleep: $remaining-ms ms"
    return remaining-ms

  set-alarm:
    current-time/TimeInfo := rtc.now.local
    logger.debug "Current time: $current-time"
    current-second := current-time.s
    next-tenth-seconds := ((current-second % 100) - (current-second % 10)) + 10
    logger.debug "current-second: $current-second, next-tenth-seconds: $next-tenth-seconds"
    next-time/TimeInfo := rtc.now.local.with --s=next-tenth-seconds --ns=0
    timer-ms := next-time.time.ms-since-epoch - current-time.time.ms-since-epoch
    rtc.count-down-timer --ms=timer-ms --enable-interrupt=true