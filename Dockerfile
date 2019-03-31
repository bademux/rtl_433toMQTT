FROM alpine:3.9

MAINTAINER bademux

RUN apk add --no-cache libusb-dev mosquitto-clients && \
    apk add --no-cache --virtual .build-deps git bash cmake build-base libusb-dev mosquitto-clients

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
    
RUN apk del .build-deps

WORKDIR /

COPY ./entrypoint.sh /opt

ENTRYPOINT ["sh", "/opt/entrypoint.sh"]

