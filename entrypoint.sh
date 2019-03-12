#!/bin/sh

while true; do 
	echo "starting forwarding RTL to mosquitto" 
     	 rtl_433 -F json ${RTL_ARGS} | mosquitto_pub -l --id RTL_433 --url ${MQTT_URL} ${MOSQUITTO_ARGS}
	sleep 5
done
