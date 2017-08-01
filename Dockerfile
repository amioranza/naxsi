FROM alpine:latest

MAINTAINER Alexandre Mioranza <amioranza@mdcnet.ninja>

WORKDIR /usr/src

ENV NGINX_VERSION nginx-1.13.3
ENV NAXSI_VERSION 0.55.3
ENV GEOIP_VERSION 1.6.9

RUN apk --update add curl build-base python-dev ca-certificates linux-headers openssl-dev \
    pcre-dev zlib-dev openssl pcre zlib python py-pip py2-geoip py-geoip bash

RUN curl -LJO http://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -xvzf ${NGINX_VERSION}.tar.gz && mv ${NGINX_VERSION} nginx

RUN curl -LJO https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}.tar.gz && \
    tar -xzvf naxsi-${NAXSI_VERSION}.tar.gz && mv naxsi-${NAXSI_VERSION} naxsi

RUN curl -LJO https://github.com/maxmind/geoip-api-c/releases/download/v${GEOIP_VERSION}/GeoIP-${GEOIP_VERSION}.tar.gz && \
    tar -zxvf GeoIP-${GEOIP_VERSION}.tar.gz && \
    cd GeoIP-${GEOIP_VERSION} && \
    ./configure && \
    make && \
    make check && \
    make install

RUN curl -LJO http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz && \
    gunzip GeoIP.dat.gz && \
    mkdir -p /usr/local/share/GeoIP/ && \
    mv GeoIP.dat /usr/local/share/GeoIP/

RUN cd nginx && ./configure \
    --add-module=../naxsi/naxsi_src/ \
    --prefix=/etc/nginx \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/run/nginx.pid \
    --lock-path=/run/nginx.lock \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-stream_ssl_module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    --with-http_v2_module \
    --with-http_auth_request_module \
    --with-http_geoip_module && \
    make && \
    make install && \
    pip install GeoIP && \
    rm /usr/local/lib/libGeoIP.a && \
    rm -rf /var/cache/apk/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    mkdir -p /etc/naxsi && \
    cp /usr/src/naxsi/naxsi_config/naxsi_core.rules /etc/naxsi && \
    mkfifo /var/log/nginx/error_pipe.log

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/sites-enabled /etc/nginx/sites-enabled
COPY default.html /var/www/html/index.html
COPY 403.html /var/www/html/403.html
COPY ssl-cert.pem /etc/nginx/ssl/ssl-cert.pem
COPY ssl-key.pem /etc/nginx/ssl/ssl-key.pem
COPY naxsi/nxapi /opt/nxapi
COPY naxsi_whitelist.rules /etc/naxsi/naxsi_whitelist.rules
COPY naxsi_startup.sh /

RUN chmod +x /naxsi_startup.sh && \
    cd /opt/nxapi && pip install -r requirements.txt && python setup.py install

EXPOSE 80 443

WORKDIR /

CMD ["/naxsi_startup.sh", "es-layer"]
