#FROM alarm32v7/alpine:3.9
FROM alpine:3.9

MAINTAINER bademux

ENV MQTT_URL="mqtt://127.0.0.1:1883/rtl_433"
ENV RTL_ARGS="-C si -M utc"
ENV MOSQUITTO_ARGS=""

COPY ./entrypoint.sh /

RUN apk add --update git cmake build-base libusb-dev mosquitto-clients

WORKDIR /tmp

RUN echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf && \
    git clone git://git.osmocom.org/rtl-sdr.git && \
    mkdir rtl-sdr/build && \
    cd rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON && \
    make  && \
    make install && \
    cd / && \
    rm -rf /tmp/rtl-sdr

RUN git clone https://github.com/merbanan/rtl_433.git && \
    cd rtl_433 && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/rtl_433

RUN apk del git cmake build-base bash && \
    rm -rf /var/cache/apk/*

WORKDIR /

ENTRYPOINT rtl_433 -F json ${RTL_ARGS} | mosquitto_pub -l --id RTL_433 --url ${MQTT_URL} ${MOSQUITTO_ARGS}

