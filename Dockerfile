FROM alpine:3.18

LABEL description="rTorrent & ruTorrent & Filebot (based on Alpine)" \
      maintainer="Djerfy <djerfy@gmail.com>" \
      repository="https://github.com/djerfy/docker-rutorrent"

ARG BUILD_CORES
ARG VER_MEDIAINFO="20.03"
ARG VER_RTORRENT="v0.9.8"
ARG VER_LIBTORRENT="v0.13.8"
ARG VER_RUTORRENT="4.1.5"
ARG VER_LIBZEN="0.4.38"
ARG VER_FILEBOT="4.9.1"
ARG VER_CHROMAPRINT="1.5.0"
ARG VER_GEOIPUPDATE="4.3.0"
ARG VER_GEOIPMODULE="1.1.1"

ENV UID="991" \
    GID="991" \
    WEBROOT="/" \
    RTORRENT_PORT="6881" \
    RTORRENT_DHT="off" \
    PKG_CONFIG_PATH="/usr/local/lib/pkg_config" \
    FILEBOT_METHOD="symlink" \
    FILEBOT_MOVIES="{n} ({y})" \
    FILEBOT_SERIES="{n}/Season {s.pad(2)}/{s00e00} - {t}" \
    FILEBOT_ANIMES="{n}/{e.pad(3)} - {t}" \
    FILEBOT_MUSICS="{n}/{fn}" \
    FILEBOT_LANG="en" \
    FILEBOT_CONFLICT="skip"

# Install packages and dependencies
RUN set -xe && \
    apk upgrade --no-cache && \
    apk add --no-cache build-base libtool automake autoconf wget libressl-dev ncurses-dev curl-dev \
        zlib-dev libnl3-dev libsigc++-dev linux-headers ffmpeg libnl3 ca-certificates gzip zip unrar \
        curl c-ares tini supervisor geoip su-exec nginx php7 php7-fpm php7-json php7-opcache php7-apcu \
        php7-mbstring libressl file findutils tar xz screen findutils bzip2 bash git sox cppunit-dev \
        cppunit openjdk11-jre java-jna-native binutils wget geoip-dev php7-pear php7-dev tzdata cksfv \
        php7-ctype php7-phar php7-bcmath php7-session php7-curl libmediainfo nss linux-headers shadow

# Download sources tools
RUN set -xe && \
    git clone https://github.com/esmil/mktorrent /tmp/mktorrent && \
    git clone https://github.com/mirror/xmlrpc-c /tmp/xmlrpc-c && \
    git clone -b ${VER_LIBTORRENT} https://github.com/rakshasa/libtorrent /tmp/libtorrent && \
    git clone -b ${VER_RTORRENT} https://github.com/rakshasa/rtorrent /tmp/rtorrent && \
    wget https://mediaarea.net/download/binary/mediainfo/${VER_MEDIAINFO}/MediaInfo_CLI_${VER_MEDIAINFO}_GNU_FromSource.tar.gz \
        -O /tmp/MediaInfo_CLI_${VER_MEDIAINFO}_GNU_FromSource.tar.gz && \
    wget https://mediaarea.net/download/binary/libmediainfo0/${VER_MEDIAINFO}/MediaInfo_DLL_${VER_MEDIAINFO}_GNU_FromSource.tar.gz \
        -O /tmp/MediaInfo_DLL_${VER_MEDIAINFO}_GNU_FromSource.tar.gz && \
    wget https://mediaarea.net/download/source/libzen/${VER_LIBZEN}/libzen_${VER_LIBZEN}.tar.bz2 \
        -O /tmp/libzen_${VER_LIBZEN}.tar.bz2 && \
    wget https://get.filebot.net/filebot/FileBot_${VER_FILEBOT}/FileBot_${VER_FILEBOT}-portable.tar.xz \
        -O /tmp/filebot.tar.xz && \
    wget https://github.com/acoustid/chromaprint/releases/download/v${VER_CHROMAPRINT}/chromaprint-fpcalc-${VER_CHROMAPRINT}-linux-x86_64.tar.gz \
        -O /tmp/chromaprint-fpcalc-${VER_CHROMAPRINT}-linux-x86_64.tar.gz && \
    wget https://github.com/maxmind/geoipupdate/releases/download/v${VER_GEOIPUPDATE}/geoipupdate_${VER_GEOIPUPDATE}_linux_amd64.tar.gz \
        -O /tmp/geoipupdate.tar.gz

# Decompress sources tools
RUN set -xe && \
    mkdir -p /tmp /filebot && \
    cd /tmp && \
    tar xjf libzen_${VER_LIBZEN}.tar.bz2 && \
    tar xzf MediaInfo_DLL_${VER_MEDIAINFO}_GNU_FromSource.tar.gz && \
    tar xzf MediaInfo_CLI_${VER_MEDIAINFO}_GNU_FromSource.tar.gz && \
    tar xvf /tmp/chromaprint-fpcalc-${VER_CHROMAPRINT}-linux-x86_64.tar.gz && \
    tar xvf /tmp/geoipupdate.tar.gz && \
    cd /filebot && \
    tar xJf /tmp/filebot.tar.xz

# Compile ZenLib tool
RUN set -xe && \
    cd /tmp/ZenLib/Project/GNU/Library && \
    ./autogen.sh && \
    ./configure \
        --prefix=/usr/local \
        --enable-shared \
        --disable-static && \
    make && \
    make install && \
    ln -sf /usr/local/lib/libzen.so.0.0.0 /filebot/lib/Linux-x86_64/libzen.so

# Compile mkTorrent
RUN set -xe && \
    cd /tmp/mktorrent && \
    # patch int64_t type name
    sed -i 's/#include "ll.h"/#include "ll.h"\n#include <stdint.h>/' mktorrent.h && \
    make -j ${BUILD_CORES-$(grep -c "processor" /proc/cpuinfo)} && \
    make install

# Compile MediaInfo
RUN set -xe && \
    cd /tmp/MediaInfo_DLL_GNU_FromSource && \
    ./SO_Compile.sh && \
    cd /tmp/MediaInfo_DLL_GNU_FromSource/ZenLib/Project/GNU/Library && \
    make install && \
    cd /tmp/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library && \
    make install && \
    cd /tmp/MediaInfo_CLI_GNU_FromSource && \
    ./CLI_Compile.sh && \
    cd /tmp/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI && \
    make install && \
    ln -sf /usr/local/lib/libzen.so.0.0.0 /filebot/lib/Linux-x86_64/libzen.so

# Compile xmlrpc-c
RUN set -xe && \
    cd /tmp/xmlrpc-c/stable && \
    ./configure && \
    make -j ${BUILD_CORES-$(grep -c "processor" /proc/cpuinfo)} && \
    make install

# Compile libtorrent
RUN set -xe && \
    cd /tmp/libtorrent && \
    ./autogen.sh && \
    ./configure \
        --disable-debug \
        --disable-instrumentation && \
    make -j ${BUILD_CORES-$(grep -c "processor" /proc/cpuinfo)} && \
    make install

# Compile rTorrent
RUN set -xe && \
    cd /tmp/rtorrent && \
    ./autogen.sh && \
    ./configure \
        --enable-ipv6 \
        --disable-debug \
        --with-xmlrpc-c && \
    make -j ${BUILD_CORES-$(grep -c "processor" /proc/cpuinfo)} && \
    make install

# Install ruTorrent
RUN set -xe && \
    mkdir -p /var/www/html && \
    git clone --recurse-submodules https://github.com/Novik/ruTorrent.git /rutorrent/app && \
    git clone https://github.com/mcrapet/plowshare /tmp/plowshare && \
    git clone https://github.com/xombiemp/ruTorrentMobile /var/www/html/rutorrent/plugins/mobile && \
    git clone https://github.com/Phlooo/ruTorrent-MaterialDesign /var/www/html/rutorrent/plugins/theme/themes/materialdesign && \
    git clone https://github.com/djerfy/ruTorrent-plugins /tmp/djerfy-plugins && \
    git clone https://github.com/Gyran/rutorrent-instantsearch /var/www/html/rutorrent/plugins/instantsearch && \
    git clone https://github.com/Gyran/rutorrent-ratiocolor /var/www/html/rutorrent/plugins/ratiocolor && \
    git clone https://github.com/Micdu70/geoip2-rutorrent /var/www/html/rutorrent/plugins/geoip2 && \
    sed -i "s/'mkdir'.*$/'mkdir',/" /tmp/djerfy-plugins/filemanager/flm.class.php && \
    sed -i 's#.*/usr/bin/rar.*##' /tmp/djerfy-plugins/filemanager/conf.php && \
    sed -i 's/version: "[[:digit:]].[[:digit:]]\{1,2\}",/version: "'${VER_RUTORRENT}'",/g' /var/www/html/rutorrent/js/webui.js && \
    mv /var/www/html/rutorrent /var/www/html/torrent && \
    mv /tmp/djerfy-plugins/* /var/www/html/torrent/plugins/ && \
    rm -Rf /var/www/html/torrent/plugins/geoip && \
    rm -Rf /var/www/html/torrent/plugins/_cloudflare && \
    rm -Rf /tmp/djerfy-plugins

# Install GeoIP (php module)
RUN set -xe && \
    pecl install geoip-${VER_GEOIPMODULE} && \
    chmod +x /usr/lib/php7/modules/geoip.so

# Install GeoIP (tool)
RUN set -xe && \
    mkdir -p /usr/local/share/GeoIP /usr/local/bin /usr/local/etc && \
    mv /tmp/geoipupdate_${VER_GEOIPUPDATE}_linux_amd64/geoipupdate /usr/local/bin/geoipupdate && \
    echo -ne "AccountID YOUR_ACCOUNT_ID_HERE\nLicenseKey YOUR_LICENSE_KEY_HERE\n" > /usr/local/etc/GeoIP.conf && \
    echo -ne "EditionIDs GeoLite2-Country GeoLite2-City\nPreserveFileTimes 2\n" >> /usr/local/etc/GeoIP.conf

# Install Plowshare
RUN set -xe && \
    cd /tmp/plowshare && \
    make

# Install ChromaPrint
RUN set -xe && \
    cd /tmp && \
    mv chromaprint-fpcalc-${VER_CHROMAPRINT}-linux-x86_64/fpcalc /usr/local/bin/fpcalc

# Cleanup
RUN set -xe && \
    strip -s /usr/local/bin/rtorrent && \
    strip -s /usr/local/bin/mktorrent && \
    strip -s /usr/local/bin/mediainfo && \
    strip -s /usr/local/bin/fpcalc && \
    strip -s /usr/local/bin/geoipupdate && \
    apk del --no-cache build-base libtool automake autoconf libressl-dev ncurses-dev curl-dev \
        zlib-dev libnl3-dev cppunit-dev binutils linux-headers libsigc++-dev php7-pear php7-dev \
        geoip-dev && \
    rm -Rf /tmp/*

# Configure
COPY rootfs /
VOLUME /data /config
EXPOSE 8080

# Starting
RUN set -xe && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]

