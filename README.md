# RTL433 to mqtt gateway

most code grabbed from https://github.com/roflmao/rtl2mqtt
and some ideas https://github.com/mverleun/RTL433-to-mqttmttq

# Run
To run on host 
```bash
docker run --read-only --network="host" --device=/dev/bus/usb/001/008 rtl_433mqtt:latest\
-e "MQTT_URL=mqtt://127.0.0.1:1883/rtl_433"\
-e "RTL_ARGS=-C si -M utc -g 25"
```

- *--network="host"* to access host on 127.0.0.1 (test only).
-*--device=/dev/bus/usb/001/008* mandatory rtl device ```lsusb``` to check bus\device name.
- *MQTT_URL* mandatory mqtt url *mqtt(s)://[username[:password]@]host[:port]/topic*
- *RTL_ARGS* optional arguments to rtl_433, alternatively */etc/rtl_433/rtl_433.conf* file can be mounted to customize rtl_433
- *MOSQUITTO_ARGS* optional arguments to mosquitto_pub
