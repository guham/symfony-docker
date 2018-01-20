FROM php:7.1-fpm

ARG timezone

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
        git \
        unzip \
        libicu-dev \
        zlib1g-dev \
        libssl-dev \
        pkg-config \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -xe \
    && docker-php-ext-configure \
        intl \
    && docker-php-ext-install \
        intl \
        opcache \
        zip \
        pdo \
        pdo_mysql \
        pdo_pgsql \
    && pecl install \
        apcu \
        xdebug \
        mongodb \
        redis \
    && docker-php-ext-enable \
        apcu \
        xdebug \
        mongodb \
        redis

COPY php.ini /usr/local/etc/php/php.ini
RUN sed -i -e "s#TIMEZONE#$timezone#g" /usr/local/etc/php/php.ini

COPY xdebug.ini /tmp/xdebug.ini
RUN cat /tmp/xdebug.ini >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN rm /tmp/xdebug.ini

COPY --from=composer:1.6 /usr/bin/composer /usr/bin/composer
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER 1
# create composer cache directory
RUN mkdir -p /var/www/.composer && chown -R www-data /var/www/.composer

RUN usermod -u 1000 www-data

WORKDIR /srv