ARG PHP_VERSION=7.2
ARG NGINX_VERSION=1.15
ARG REDIS_VERSION=4
ARG NODE_VERSION=10

FROM php:${PHP_VERSION}-fpm-alpine AS symfony_docker_php

RUN apk add --no-cache \
		unzip \
		acl \
		file \
		gettext \
		git \
	;

ARG APCU_VERSION=5.1.12
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-dev \
		libzip-dev \
		zlib-dev \
        postgresql-dev \
	; \
	\
	docker-php-ext-configure zip --with-libzip; \
	docker-php-ext-install -j$(nproc) \
		intl \
		pdo \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
	pecl install \
		apcu-${APCU_VERSION} \
		xdebug \
        mongodb \
        redis \
	; \
	pecl clear-cache; \
	docker-php-ext-enable \
		apcu \
		opcache \
		xdebug \
        mongodb \
		redis \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .api-phpexts-rundeps $runDeps; \
	\
	apk del .build-deps


COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/xdebug.ini /tmp/xdebug.ini
RUN cat /tmp/xdebug.ini >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN rm /tmp/xdebug.ini

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"

WORKDIR /srv

# build for production
ARG APP_ENV=prod

COPY composer.json composer.lock symfony.lock ./
RUN set -eux; \
	composer install --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress --no-suggest; \
	composer clear-cache

COPY . .

RUN set -eux; \
	mkdir -p var/cache var/log; \
	composer dump-autoload --classmap-authoritative --no-dev; \
	#composer run-script --no-dev post-install-cmd; \
	chmod +x bin/console; sync

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]

FROM nginx:${NGINX_VERSION}-alpine AS symfony_docker_nginx

RUN apk add --no-cache \
		openssl \
		gettext \
		bash \
	;

RUN printf "[SAN]\nsubjectAltName=DNS:localhost" >> /etc/ssl/openssl.cnf
RUN mkdir -p /etc/nginx/ssl/

RUN openssl genrsa -des3 -passout pass:NotSecure -out server.pass.key 2048
RUN openssl rsa -passin pass:NotSecure -in server.pass.key -out /etc/nginx/ssl/cert.key
RUN rm server.pass.key
RUN openssl req -new -passout pass:NotSecure -key /etc/nginx/ssl/cert.key -out server.csr \
    -subj "/C=MX/ST=Mexico/L=Mexico/O=Symfony-Docker/CN=localhost" -config /etc/ssl/openssl.cnf
RUN openssl x509 -req -sha256 -days 365 -in server.csr -signkey /etc/nginx/ssl/cert.key \
    -out /etc/nginx/ssl/cert.crt -extensions SAN -extfile /etc/ssl/openssl.cnf

ADD docker/nginx/nginx.conf /etc/nginx/
COPY docker/nginx/default.conf /etc/nginx/conf.d/
RUN rm /var/log/nginx/access.log /var/log/nginx/error.log

FROM redis:${REDIS_VERSION}-alpine AS symfony_docker_redis

FROM node:${NODE_VERSION}-alpine AS symfony_docker_node

RUN apk add --no-cache su-exec && \
    addgroup bar && \
    adduser -D -h /home -s /bin/sh -G bar foo

COPY docker/node/entrypoint.sh /entrypoint
RUN chmod +x /entrypoint

WORKDIR /srv

ENTRYPOINT ["/entrypoint"]
