FROM tiredofit/alpine:edge
LABEL maintainer="Dave Conroy (dave at tiredofit dot ca)"

### Set Environment Variables
   ENV ENABLE_CRON=FALSE \
       ENABLE_SMTP=FALSE

RUN apk add --no-cache tzdata bash ca-certificates && \
    update-ca-certificates

ENV INFLUXDB_VERSION 1.7.1
RUN set -ex && \
    apk add --no-cache --virtual .build-deps wget gnupg tar && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz.asc && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    gpg --batch --verify influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz.asc influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz && \
    rm -f /usr/src/influxdb-*/influxdb.conf && \
    chmod +x /usr/src/influxdb-*/* && \
    cp -a /usr/src/influxdb-*/* /usr/bin/ && \
    rm -rf *.tar.gz* /usr/src /root/.gnupg && \
    apk del .build-deps

### Dependencies
   RUN set -ex && \
       echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
       apk update && \
       apk upgrade && \
       apk add --virtual .db-backup-build-deps \
           build-base \
           bzip2-dev \
           git \
           xz-dev \
           && \
           \
       apk add --virtual .db-backup-run-deps  \
       	   bzip2 \
           mongodb-tools \
           mariadb-client \
           libressl \
           pigz \
           postgresql \
           postgresql-client \
           redis \
           xz \
           && \
        apk add \
            pixz@testing \
           && \
          \
          cd /usr/src && \
          mkdir -p pbzip2 && \
          curl -ssL https://launchpad.net/pbzip2/1.1/1.1.13/+download/pbzip2-1.1.13.tar.gz | tar xvfz - --strip=1 -C /usr/src/pbzip2 && \
          cd pbzip2 && \
          make && \
          make install && \
          \
          # Cleanup
          rm -rf /usr/src/* && \
          apk del .db-backup-build-deps && \
          rm -rf /tmp/* /var/cache/apk/*

### S6 Setup
    ADD install  /
