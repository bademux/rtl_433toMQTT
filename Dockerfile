FROM scratch as caching-downloader
ADD https://github.com/merbanan/rtl_433/archive/20.11.tar.gz /rtl_433.tar.gz

FROM alpine:3.13.2 as builder
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib"
RUN apk add --no-cache --update autoconf automake libtool build-base rtl-sdr libusb-dev bash
COPY --from=caching-downloader / /tmp
WORKDIR /build
RUN tar -zxvf /tmp/rtl_433.tar.gz --strip-components=1
RUN autoreconf -i && ./configure && make && make install
RUN echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

FROM alpine:3.13.2
MAINTAINER bademux
ENV RTL_OPTS=""
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib"
RUN apk add --no-cache --update libusb
COPY --from=builder /usr/local/ /usr/local/
COPY --from=builder /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf
COPY --from=builder /etc/udev/rules.d/rtl-sdr.rules /etc/udev/rules.d/rtl-sdr.rules
RUN adduser -D -H user -G usb
USER user
ENTRYPOINT rtl_433 $RTL_OPTS
