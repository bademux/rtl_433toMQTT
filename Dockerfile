FROM alpine:3.11 as builder

ARG SOURCE_DIR=""

ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib"


RUN apk add --no-cache --update git cmake build-base libusb-dev bash

ADD ./tmp /tmp/proj_tmp
WORKDIR /tmp/proj_tmp

RUN cd /tmp/proj_tmp/rtl-sdr && \
    mkdir build && cd build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON && \
    make  && \
    make install

RUN cd /tmp/proj_tmp/rtl_433 && \
    mkdir build && cd build && \
    cmake ../ && \
    make && \
    make install

RUN echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

FROM alpine:3.11

MAINTAINER bademux

ENV RTL_OPTS=""
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib"

WORKDIR /

COPY --from=builder /usr/local/ /usr/local/
COPY --from=builder /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf
COPY --from=builder /etc/udev/rules.d/rtl-sdr.rules /etc/udev/rules.d/rtl-sdr.rules

RUN apk add --no-cache --update libusb

RUN adduser -D -H user -G usb

USER user

ENTRYPOINT rtl_433 $RTL_OPTS
