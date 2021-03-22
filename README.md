
# Multiarch RTL433 to MQTT gateway docker

# HowTo
To run on host 
```bash
vidPid="0bda:2838"
devPath="/dev/bus/usb/$(lsusb -d $vidPid | sed 's/^.*Bus\s\([0-9]\+\)\sDevice\s\([0-9]\+\).*$/\1\/\2/g')"
chown $USER $devPath
docker run --read-only --network="host" --device=$devPath \
 -e RTL_OPTS="-g25 -F mqtt://localhost:1883,retain=0,devices=sensors/rtl_433/P[protocol:255]/C[channel:0] -M newmodel -M protocol -M time:iso" \ 
 bademux/rtl_433tomqtt:latest
```

- *--network="host"* to access host on 127.0.0.1 (test only).
-*--device=/dev/bus/usb/001/008* mandatory rtl device ```lsusb``` to check bus\device name.
-  env var *RTL_OPTS* arguments to rtl_433, alternatively */etc/rtl_433/rtl_433.conf* file can be mounted with -c rtl_433.conf

to test it localy run:
```bash
mosquitto_sub -t rtl_433
```

# Ref
- MQTT with rtl_433 https://github.com/merbanan/rtl_433/wiki/How-to-integrate-rtl_433-sensors-into-openHAB-via-MQTT
- Multiarch build conf for travis https://raw.githubusercontent.com/moikot/docker-tools/e648acc47ed07f7f1b52c258d8049a04cb096ab3/scripts.sh
- git repo https://github.com/bademux/rtl_433toMQTT
- docker repo https://hub.docker.com/r/bademux/rtl_433tomqtt

