import gpio

main:
  r := gpio.Pin 5 --output=true 
  g := gpio.Pin 6 --output=true 
  b := gpio.Pin 7 --output=true
  r.set 1
  g.set 1
  b.set 1

  while true:
    print "red"
    r.set 0
    g.set 1
    b.set 1
    sleep --ms=1000
    print "green"
    r.set 1
    g.set 0
    b.set 1
    sleep --ms=1000
    print "blue"
    r.set 1
    g.set 1
    b.set 0
    sleep --ms=1000