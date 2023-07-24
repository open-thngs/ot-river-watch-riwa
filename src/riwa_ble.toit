import ble show *
import log

BLE_SERVICE_UUID ::= BleUuid "610e8afe-0618-49f4-a49c-7330da8607d5"
BLE_TEMPERATURE_CHARACTERISTIC_UUID ::= BleUuid "bc424fa4-c969-4f72-808e-55c0ad1b1ed1"
BLE_PRESSURE_CHARACTERISTIC_UUID ::= BleUuid "42a97385-5b71-40a5-b75d-69211027e577"
BLE_HEIGHT_CHARACTERISTIC_UUID ::= BleUuid "99ff002a-0e00-4b52-a0ab-31f7de4f5017"

logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="ble"

class RiWaBLEServer:
  tempterature_ble/LocalCharacteristic? := ?
  pressure_ble/LocalCharacteristic? := ?
  current_height_ble/LocalCharacteristic? := ?

  service/LocalService? := ?
  peripheral/Peripheral? := ?

  constructor:
    adapter := Adapter 
    adapter.set_preferred_mtu 512
    peripheral = adapter.peripheral

    service = peripheral.add_service BLE_SERVICE_UUID
    tempterature_ble = service.add_write_only_characteristic BLE_TEMPERATURE_CHARACTERISTIC_UUID
    pressure_ble = service.add_write_only_characteristic BLE_PRESSURE_CHARACTERISTIC_UUID
    current_height_ble = service.add_write_only_characteristic BLE_HEIGHT_CHARACTERISTIC_UUID

  start:
    service.deploy

    connection_mode := BLE_CONNECT_MODE_UNDIRECTIONAL
    peripheral.start_advertise --connection_mode=connection_mode
      AdvertisementData
        --name="RiWa-Station"
        --check_size=false 
        --connectable=true
        --service_classes=[BLE_SERVICE_UUID]

    logger.debug "Advertising: $BLE_SERVICE_UUID with name RiWa-Station"

  stop:
    peripheral.stop_advertise

  wait_and_read_pressure timeout=0 -> float:
    if timeout != 0:
      exception := catch: with_timeout --ms=timeout:
        return float.parse pressure_ble.read.to_string
      if exception:
        return 0.0
    return float.parse pressure_ble.read.to_string

  wait_and_read_temperature timeout-> float:
    if timeout != 0:
      exception := catch: with_timeout --ms=timeout:
        return float.parse tempterature_ble.read.to_string
      if exception:
        return 0.0
    return float.parse tempterature_ble.read.to_string

class RiWaBLEClient:
  adapter := ?
  central := ?
  remote_device/RemoteDevice? := null
  temperature_characteristic/RemoteCharacteristic? := null
  pressure_characteristic/RemoteCharacteristic? := null

  constructor: 
    adapter = Adapter
    central = adapter.central
  
  connect timeout/int=3:
    address := find_with_service central BLE_SERVICE_UUID timeout
    remote_device = central.connect address
    services := remote_device.discover_services [BLE_SERVICE_UUID]
    master_ble/RemoteService := services.first

    characteristics := master_ble.discover_characteristics [BLE_PRESSURE_CHARACTERISTIC_UUID, BLE_TEMPERATURE_CHARACTERISTIC_UUID]
    characteristics.do: | characteristic/RemoteCharacteristic |
      if characteristic.uuid == BLE_PRESSURE_CHARACTERISTIC_UUID:
        pressure_characteristic = characteristic
      else if characteristic.uuid == BLE_TEMPERATURE_CHARACTERISTIC_UUID:
        temperature_characteristic = characteristic

  find_with_service central/Central service/BleUuid duration/int=3:
    central.scan --duration=(Duration --s=duration): | device/RemoteScannedDevice |
      if device.data.service_classes.contains service:
          logger.debug "Found device with service $service: $device"
          return device.address
    throw "no device found"

  write_pressure value/ByteArray:
    if pressure_characteristic: 
      pressure_characteristic.write value
  
  write_temperature value/ByteArray:
    if temperature_characteristic: 
      temperature_characteristic.write value