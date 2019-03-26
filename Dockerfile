FROM alpine:3.11

MAINTAINER bademux

ARG RTL_SDR_VER="0.6.0"
ARG RTL_433_VER="20.02"
ENV RTL_OPS=""
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib"

RUN apk add --no-cache --update git cmake build-base libusb-dev

WORKDIR /tmp
RUN apk add --no-cache --virtual .build-deps git bash cmake build-base && \
    echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf && \
    git clone -b $RTL_SDR_VER git://git.osmocom.org/rtl-sdr.git --depth 1 && \
    mkdir rtl-sdr/build && \
    cd rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON && \
    make  && \
    make install && \
    rm -rf rtl-sdr && \
    cd /tmp && \
    git clone  -b $RTL_433_VER git://github.com/merbanan/rtl_433.git  --depth 1  && \
    cd rtl_433 && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make && \
    make install && \
    cd / && \
    rm -rf rtl_433 /rtl_433 && \
    apk del .build-deps

WORKDIR /

ENTRYPOINT rtl_433 $RTL_OPS
