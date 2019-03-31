# RTL433 to mqtt gateway

Ideas borrowed from https://github.com/roflmao/rtl2mqtt and https://github.com/mverleun/RTL433-to-mqttmttq
Multiarch build conf for travis https://github.com/moikot/golang-dep

# Run
To run on host 
```bash
vidPid="0bda:2838"
path="/dev/bus/usb/$(lsusb -d $vidPid | sed 's/^.*Bus\s\([0-9]\+\)\sDevice\s\([0-9]\+\).*$/\1\/\2/g')"
docker run --read-only --network="host" --device=$path bademux/rtl_433tomqtt:latest \
	--rtl="-g25" \ #optional rtl_433 params
	--mqtt="--url mqtt://127.0.0.1:1883/rtl_433" #optional mosquitto_pub params
```

- *--network="host"* to access host on 127.0.0.1 (test only).
-*--device=/dev/bus/usb/001/008* mandatory rtl device ```lsusb``` to check bus\device name.
- *--rtl* optional arguments to rtl_433, alternatively */etc/rtl_433/rtl_433.conf* file can be mounted
- *--mqtt* optional arguments to mosquitto_pub, can be set by providing *--mqtt="--url mqtt(s)://[username[:password]@]host[:port]/topic"*

to test it localy run:
```bash
mosquitto_sub -t rtl_433
```
