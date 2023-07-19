# vim:set ft=dockerfile:
FROM ubuntu:jammy

# See for more info:
# https://unit.nginx.org/installation/#docker-dockerhub
# https://github.com/nginx/unit/tree/master/pkg/docker

RUN \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
	groupadd -r unit && useradd -r -g unit unit; \
	set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates dirmngr gnupg wget; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
# install gosu
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/latest/download/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/latest/download/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true; \
# install drush launcher
	wget -O /usr/local/bin/drush https://github.com/drush-ops/drush-launcher/releases/latest/download/drush.phar; \
	chmod +x /usr/local/bin/drush; \
# install drupal console launcher
	wget -O /usr/local/bin/drupal https://github.com/hechoendrupal/drupal-console-launcher/releases/latest/download/drupal.phar; \
	chmod +x /usr/local/bin/drupal; \
# add nginx unit repo
# https://unit.nginx.org/installation/#ubuntu
	wget -O /usr/share/keyrings/nginx-keyring.gpg https://unit.nginx.org/keys/nginx-keyring.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ jammy unit" > /etc/apt/sources.list.d/unit.list; \
# hold package version 1.29.1-1~jammy
	echo > /etc/apt/preferences.d/unit; \
	echo "Package: unit" >> /etc/apt/preferences.d/unit; \
	echo "Pin: version 1.29.1-1~jammy" >> /etc/apt/preferences.d/unit; \
	echo "Pin-Priority: 1002" >> /etc/apt/preferences.d/unit; \
	echo >> /etc/apt/preferences.d/unit; \
	echo "Package: unit-php" >> /etc/apt/preferences.d/unit; \
	echo "Pin: version 1.29.1-1~jammy" >> /etc/apt/preferences.d/unit; \
	echo "Pin-Priority: 1002" >> /etc/apt/preferences.d/unit; \
# installing the required packages
	apt-get update; \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		awscli \
		ca-certificates \
		composer \
		cron \
		curl \
		ffmpeg \
		git \
		msmtp \
		openssh-client \
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
		scour \
		unit \
		unit-php \
		unzip \
                ; \
	rm -rf /var/lib/apt/lists/*; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/cache/apt/archives/*; \
	unitd --version; \
	php -v; \
	ffmpeg -version; \
	aws --version; \
	composer -V -n; \
	msmtp --version; \
# preparing state directory
	rm -rf /var/lib/unit; \
	mkdir -p /var/lib/unit; \
	chown -R unit:unit /var/lib/unit; \
# use msmtp as sendmail
	ln -sf /usr/bin/msmtp /usr/sbin/sendmail; \
# preparing init dir
	mkdir /docker-entrypoint.d; \
# log to stdout
	ln -sf /dev/stdout /var/log/unit.log

COPY docker-entrypoint*.sh /

STOPSIGNAL SIGTERM

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]