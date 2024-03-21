import ..espnow.rgb-led show RGBLED

main:
  led := RGBLED
  colors := [[255, 255, 255],[255, 0, 0],[0, 255, 0],[0, 0, 255],[255, 0, 255],[125, 68, 255],[0, 255, 255],[255, 255, 0],[0, 0, 0]]

  while true:
    colors.do: | color |
      led.set-color color[0] color[1] color[2]
      100.repeat: | brightness |
        led.set_brightness brightness
        sleep --ms=3
      100.repeat: | brightness |
        led.set_brightness 100 - brightness
        sleep --ms=3