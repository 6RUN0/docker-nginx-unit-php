# https://unit.nginx.org/howto/modules/

# Base image with package updates and package mirror change
FROM debian:bookworm-slim AS base_image
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_MIRROR="http://mirror.selectel.ru/debian"
ARG DEBIAN_SECURITY_MIRROR="http://mirror.selectel.ru/debian-security"
# Mirror of packages.sury.org
#  - https://packages.sury.org/php/
#  - http://debian.octopuce.fr/sury-php/
ARG SURY_MIRROR="http://mirror.yandex.ru/mirrors/packages.sury.org/php/"
RUN \
    set -eux; \
    apt_mirror() { \
    sed -i \
    -e "s|http://deb\.debian\.org/debian-security|$3|g" \
    -e "s|http://deb\.debian\.org/debian|$2|g" \
    $1; \
    }; \
    [ -w "/etc/apt/sources.list.d/debian.sources" ] && \
    apt_mirror "/etc/apt/sources.list.d/debian.sources" "${DEBIAN_MIRROR}" "${DEBIAN_SECURITY_MIRROR}"; \
    [ -w "/etc/apt/sources.list" ] && \
    apt_mirror "/etc/apt/sources.list" "${DEBIAN_MIRROR}" "${DEBIAN_SECURITY_MIRROR}"; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    tini \
    ; \
    # https://unit.nginx.org/installation/#debian
    curl -fsSL -o /usr/share/keyrings/nginx-keyring.gpg https://unit.nginx.org/keys/nginx-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/debian/ bookworm unit" > /etc/apt/sources.list.d/unit.list; \
    curl -fsSL -o /usr/share/keyrings/org.sury.packages.php.gpg ${SURY_MIRROR}apt.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/org.sury.packages.php.gpg] ${SURY_MIRROR} bookworm main" > /etc/apt/sources.list.d/org.sury.packages.php.list; \
    echo "Package: *" > /etc/apt/preferences.d/org-sury-packages-php; \
    echo "Pin: release o=deb.sury.org" >> /etc/apt/preferences.d/org-sury-packages-php; \
    echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/org-sury-packages-php;


# Base image with php 8.4
FROM base_image AS php_image
ARG DEBIAN_FRONTEND=noninteractive
RUN \
    set -eux; \
    php_ver="8.4"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libphp${php_ver}-embed \
    php${php_ver}-apcu \
    php${php_ver}-bcmath \
    php${php_ver}-bz2 \
    php${php_ver}-cli \
    php${php_ver}-curl \
    php${php_ver}-gd \
    php${php_ver}-imagick \
    php${php_ver}-intl \
    php${php_ver}-mbstring \
    php${php_ver}-mysql \
    php${php_ver}-readline \
    php${php_ver}-redis \
    php${php_ver}-tidy \
    php${php_ver}-uploadprogress \
    php${php_ver}-xml \
    php${php_ver}-xmlrpc \
    php${php_ver}-yaml \
    php${php_ver}-zip \
    ; \
    if [ "x$php_ver" = "x7.4" ]; then \
    apt-get install -y --no-install-recommends \
    php${php_ver}-apcu-bc \
    php${php_ver}-json \
    ; \
    fi; \
    if [ "x$php_ver" = "x5.6" ]; then \
    apt-get install -y --no-install-recommends \
    php${php_ver}-json \
    ; \
    fi;


# Base image with nginx unit 1.34.2-1~bookworm and php 8.4
FROM php_image AS unit_php_image
ARG DEBIAN_FRONTEND=noninteractive
RUN \
    set -eux; \
    # hold package version 1.34.2-1~bookworm
    echo > /etc/apt/preferences.d/unit; \
    echo "Package: unit" >> /etc/apt/preferences.d/unit; \
    echo "Pin: version 1.34.2-1~bookworm" >> /etc/apt/preferences.d/unit; \
    echo "Pin-Priority: 1002" >> /etc/apt/preferences.d/unit; \
    echo >> /etc/apt/preferences.d/unit; \
    echo "Package: unit-php" >> /etc/apt/preferences.d/unit; \
    echo "Pin: version 1.34.2-1~bookworm" >> /etc/apt/preferences.d/unit; \
    echo "Pin-Priority: 1002" >> /etc/apt/preferences.d/unit; \
    # add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
    groupadd -r unit; \
    useradd -r -g unit unit; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    unit \
    ; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get autoclean -y; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /var/cache/apt/archives/*; \
    # preparing state directory
    rm -rf /var/lib/unit; \
    mkdir -p /var/lib/unit; \
    chown -R unit:unit /var/lib/unit; \
    # preparing init dir
    mkdir /docker-entrypoint.d; \
    # log to stdout
    ln -sf /dev/stdout /var/log/unit.log


# Build the unit-php module
FROM unit_php_image AS builder
ARG DEBIAN_FRONTEND=noninteractive
RUN \
    set -eux; \
    php_ver="8.4"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    build-essential \
    cargo \
    devscripts \
    dirmngr \
    fakeroot \
    gnupg \
    php${php_ver}-dev \
    rustc \
    ; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    phpVer="$(php --version | sed -n -E -e 's/^PHP ([0-9]\.[0-9]).*$/\1/p')"; \
    unitVer="$(unitd --version 2>&1 | sed -n -E -e 's/unit version: ([0-9.]+)/\1/p')"; \
    unitConfigure="$(unitd --version 2>&1 | sed -n -E -e 's/--njs //g' -e 's/^configured as (.+?)--ld-opt=.*/\1/p')"; \
    unitModuleDir="$(unitd --version 2>&1 | sed -n -E -e 's/^.*--modules=(\S+).*$/\1/p')"; \
    buildDir="/usr/src/unit"; \
    mkdir -p "$buildDir/unit-php$phpVer/DEBIAN"; \
    cd "$buildDir"; \
    curl -fsSL -o unit-$unitVer.tar.gz "https://unit.nginx.org/download/unit-$unitVer.tar.gz"; \
    tar xzf "unit-$unitVer.tar.gz"; \
    cd "unit-$unitVer"; \
    sh -c "$unitConfigure"; \
    ./configure php --module=php$phpVer --config=php-config; \
    make php$phpVer; \
    [ -f "build/lib/unit/modules/php$phpVer.unit.so" ] && \
    mkdir -p $buildDir/unit-php$phpVer$unitModuleDir/usr && \
    mv build/lib $buildDir/unit-php$phpVer$unitModuleDir/usr/lib; \
    [ -f "build/php$phpVer.unit.so" ] && \
    mkdir -p "$buildDir/unit-php$phpVer$unitModuleDir" && \
    mv build/php$phpVer.unit.so "$buildDir/unit-php$phpVer$unitModuleDir"; \
    echo "Package: unit-php$phpVer" > "$buildDir/unit-php$phpVer/DEBIAN/control"; \
    echo "Version: $unitVer" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
    echo "Architecture: $dpkgArch" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
    echo "Depends: unit (= 1.34.2-1~bookworm), libphp-embed" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
    echo "Maintainer: boris_t <boris.t.66@gmail.com>" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
    echo "Description: Custom PHP $phpVer language module for NGINX Unit $unitVer" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
    dpkg-deb -b "$buildDir/unit-php$phpVer";


# See for more info:
# https://unit.nginx.org/installation/#docker-dockerhub
# https://github.com/nginx/unit/tree/master/pkg/docker
FROM unit_php_image AS final_image
ARG DEBIAN_FRONTEND=noninteractive
COPY --from=builder /usr/src/unit/*.deb /tmp
RUN \
    set -eux; \
    dpkg -i /tmp/*.deb; \
    rm -rf /tmp/*.deb; \
    unitd --version; \
    php -v;
COPY docker-entrypoint*.sh /
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
