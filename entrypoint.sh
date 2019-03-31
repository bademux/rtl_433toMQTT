#!/bin/ash
RTL_ARGS=""
MOSQUITTO_ARGS=""

for i in "$@" ; do
case $i in
    --rtl=*)
    RTL_ARGS="${i#*=}"
    ;;
    --mqtt=*)
    MOSQUITTO_ARGS="${i#*=}"
    ;;
    *)
            # unknown option
    ;;
esac
done

run(){
    while true; do 
        echo "starting forwarding RTL to mosquitto" 
        rtl_433 -F json -C si -M utc ${RTL_ARGS} | mosquitto_pub -l --id RTL_433 ${MOSQUITTO_ARGS}
        sleep 5
    done
}

run & wait $! # handle sigterm
