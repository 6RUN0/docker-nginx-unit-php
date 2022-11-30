# vim:set ft=dockerfile:
# https://unit.nginx.org/howto/modules/
FROM debian:bullseye-slim as builder
RUN \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
	set -eux; \
	apt-get update; \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates dirmngr gnupg curl apt-transport-https; \
# https://unit.nginx.org/installation/#debian
	curl -o /usr/share/keyrings/nginx-keyring.gpg https://unit.nginx.org/keys/nginx-keyring.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/debian/ bullseye unit" > /etc/apt/sources.list.d/unit.list; \
# https://deb.sury.org
	echo "138.199.37.225 packages.sury.org" >> /etc/hosts; \
	curl -o /usr/share/keyrings/org.sury.packages.php.gpg https://packages.sury.org/php/apt.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/org.sury.packages.php.gpg] https://packages.sury.org/php/ bullseye main" > /etc/apt/sources.list.d/org.sury.packages.php.list; \
	echo "Package: *" > /etc/apt/preferences.d/org-sury-packages-php; \
	echo "Pin: release o=deb.sury.org" >> /etc/apt/preferences.d/org-sury-packages-php; \
	echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/org-sury-packages-php; \
	apt-get update; \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unit php-cli php-dev libphp-embed build-essential fakeroot devscripts; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	phpVer="$(php --version | sed -n -E -e 's/^PHP ([0-9]\.[0-9]).*$/\1/p')"; \
	unitVer="$(unitd --version 2>&1 | sed -n -E -e 's/unit version: ([0-9.]+)/\1/p')"; \
	unitConfigure="$(unitd --version 2>&1 | sed -n -E -e 's/^configured as (.+?)--ld-opt=.*/\1/p')"; \
	unitModuleDir="$(unitd --version 2>&1 | sed -n -E -e 's/^.*--modules=(\S+).*$/\1/p')"; \
	buildDir="/usr/src/unit"; \
	mkdir -p "$buildDir/unit-php$phpVer/DEBIAN"; \
	cd "$buildDir"; \
	curl -o unit-$unitVer.tar.gz "https://unit.nginx.org/download/unit-$unitVer.tar.gz"; \
	tar xzf "unit-$unitVer.tar.gz"; \
	cd "unit-$unitVer"; \
	sh -c "$unitConfigure"; \
	./configure php --module=php$phpVer --config=php-config; \
	make php$phpVer; \
	mkdir -p "$buildDir/unit-php$phpVer$unitModuleDir"; \
	mv build/php$phpVer.unit.so "$buildDir/unit-php$phpVer$unitModuleDir"; \
	echo "Package: unit-php$phpVer" > "$buildDir/unit-php$phpVer/DEBIAN/control"; \
	echo "Version: $unitVer" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
	echo "Architecture: $dpkgArch" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
	echo "Depends: unit (= 1.25.0-1~bullseye), libphp-embed" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
	echo "Maintainer: boris_t <boris.t.66@gmail.com>" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
	echo "Description: Custom PHP $phpVer language module for NGINX Unit $unitVer" >> "$buildDir/unit-php$phpVer/DEBIAN/control"; \
	dpkg-deb -b "$buildDir/unit-php$phpVer"; \
	curl --upload-file "$buildDir/unit-php$phpVer.deb" "https://transfer.sh/unit-php$phpVer.dev";


FROM debian:bullseye-slim

# See for more info:
# https://unit.nginx.org/installation/#docker-dockerhub
# https://github.com/nginx/unit/tree/master/pkg/docker

COPY --from=builder /usr/src/unit/*.deb /tmp

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
# install composer
	wget -O /usr/local/bin/composer "https://github.com/composer/composer/releases/latest/download/composer.phar"; \
	wget -O /usr/local/bin/composer.asc "https://github.com/composer/composer/releases/latest/download/composer.phar.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver pgp.mit.edu --recv-keys 161DFBE342889F01DDAC4E61CBB3D576F2A0946F; \
	gpg --batch --verify /usr/local/bin/composer.asc /usr/local/bin/composer; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/composer.asc; \
	chmod +x /usr/local/bin/composer; \
# install drupal console launcher
	wget -O /usr/local/bin/drupal https://github.com/hechoendrupal/drupal-console-launcher/releases/latest/download/drupal.phar; \
	chmod +x /usr/local/bin/drupal; \
# add nginx unit repo
# https://unit.nginx.org/installation/#debian
	wget -O /usr/share/keyrings/nginx-keyring.gpg https://unit.nginx.org/keys/nginx-keyring.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/debian/ bullseye unit" > /etc/apt/sources.list.d/unit.list; \
# hold package version 1.25.0-1~bullseye
	echo > /etc/apt/preferences.d/unit; \
	echo "Package: unit" >> /etc/apt/preferences.d/unit; \
	echo "Pin: version 1.25.0-1~bullseye" >> /etc/apt/preferences.d/unit; \
	echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/unit; \
	echo >> /etc/apt/preferences.d/unit; \
	echo "Package: unit-php" >> /etc/apt/preferences.d/unit; \
	echo "Pin: version 1.25.0-1~bullseye" >> /etc/apt/preferences.d/unit; \
	echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/unit; \
	echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/debian/ bullseye unit" > /etc/apt/sources.list.d/unit.list; \
# https://deb.sury.org
	echo "138.199.37.225 packages.sury.org" >> /etc/hosts; \
	wget -O /usr/share/keyrings/org.sury.packages.php.gpg https://packages.sury.org/php/apt.gpg; \
	echo "deb [signed-by=/usr/share/keyrings/org.sury.packages.php.gpg] https://packages.sury.org/php/ bullseye main" > /etc/apt/sources.list.d/org.sury.packages.php.list; \
	echo "Package: *" > /etc/apt/preferences.d/org-sury-packages-php; \
	echo "Pin: release o=deb.sury.org" >> /etc/apt/preferences.d/org-sury-packages-php; \
	echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/org-sury-packages-php; \
# installing the required packages
	apt-get update; \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		awscli \
		bind9-host \
		curl \
		ffmpeg \
		git \
		libphp-embed \
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
		unzip \
                ; \
	dpkg -i /tmp/*.deb; \
	rm -rf /tmp/*.deb; \
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

COPY docker-entrypoint-common.sh /
COPY docker-entrypoint.sh /

STOPSIGNAL SIGTERM

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
