Flashing: `jag flash -p COM19 --chip=esp32s3 --uart-endpoint-rx=44`
Run: `jag run -D jag.disabled -D jag.timeout=5m espnow/bouy-espnow.toit`

Install container: `jag container install bouy -D jag.disabled -D jag.timeout=5m espnow/bouy-espnow.toit`
Install container: `jag container install station -D jag.disabled -D jag.timeout=5m espnow/station-espnow.toit`

Monitor: `jag monitor -p COM19 --proxy`
