FROM debian:bookworm-slim

ENV PHP_VERSION 8.2

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		curl \
		ca-certificates \
		php${PHP_VERSION} \
		php${PHP_VERSION}-fpm \
		php${PHP_VERSION}-cli \
		php${PHP_VERSION}-mysql \
		php${PHP_VERSION}-gd \
		php${PHP_VERSION}-mbstring \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php \
	&& chown -R www-data:www-data /run/php

RUN curl -fSL -o /usr/local/bin/wp \
	https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

WORKDIR /var/www/html
COPY tools/run_wordpress.sh /run_wordpress.sh

RUN chmod +x /run_wordpress.sh

EXPOSE 9000

ENTRYPOINT ["/run_wordpress.sh"]

CMD ["php-fpm8.2", "-F"]