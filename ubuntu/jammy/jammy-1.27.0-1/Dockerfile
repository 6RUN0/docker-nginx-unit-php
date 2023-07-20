# vim:set ft=dockerfile:
FROM ubuntu:jammy

ARG DEBIAN_FRONTEND noninteractive

# See for more info:
# https://unit.nginx.org/installation/#docker-dockerhub
# https://github.com/nginx/unit/tree/master/pkg/docker

RUN \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
	groupadd -r unit; \
	useradd -r -g unit unit; \
	set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates dirmngr gnupg wget; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
# add nginx unit repo
# https://unit.nginx.org/installation/#ubuntu
	wget -O /usr/share/keyrings/nginx-keyring.gpg https://unit.nginx.org/keys/nginx-keyring.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit" > /etc/apt/sources.list.d/unit.list; \
# hold package version 1.27.0-1~jammy
	echo > /etc/apt/preferences.d/unit; \
	echo "Package: unit" >> /etc/apt/preferences.d/unit; \
	echo "Pin: version 1.27.0-1~jammy" >> /etc/apt/preferences.d/unit; \
	echo "Pin-Priority: 1002" >> /etc/apt/preferences.d/unit; \
	echo >> /etc/apt/preferences.d/unit; \
	echo "Package: unit-php" >> /etc/apt/preferences.d/unit; \
	echo "Pin: version 1.27.0-1~jammy" >> /etc/apt/preferences.d/unit; \
	echo "Pin-Priority: 1002" >> /etc/apt/preferences.d/unit; \
# installing the required packages
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		php-apcu \
		php-bcmath \
		php-bz2 \
		php-cli \
		php-curl \
		php-gd \
		php-imagick \
		php-intl \
		php-json \
		php-mbstring \
		php-mysql \
		php-readline \
		php-redis \
		php-xml \
		php-xmlrpc \
		php-zip \
		unit \
		unit-php \
		; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	apt autoclean -y; \
	rm -rf /var/lib/apt/lists/*; \
	rm -rf /var/cache/apt/archives/*; \
	unitd --version; \
	php -v; \
# preparing state directory
	rm -rf /var/lib/unit; \
	mkdir -p /var/lib/unit; \
	chown -R unit:unit /var/lib/unit; \
# preparing init dir
	mkdir /docker-entrypoint.d; \
# log to stdout
	ln -sf /dev/stdout /var/log/unit.log

COPY docker-entrypoint*.sh /

STOPSIGNAL SIGTERM

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
