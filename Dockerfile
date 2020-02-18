FROM php:7.3.12-fpm



RUN  set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ghostscript \
	; \
	rm -rf /var/lib/apt/lists/*
	
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		mysqli \
		opcache \
		zip \
	; \
	pecl install imagick-3.4.4; \
	docker-php-ext-enable imagick; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*


RUN echo "opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
" >/usr/local/etc/php/conf.d/opcache-recommended.ini 



RUN  echo "error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /dev/stderr
log_errors_max_len = 1024
ignore_repeated_errors = On
ignore_repeated_source = Off
html_errors = Off
" >/usr/local/etc/php/conf.d/error-logging.ini 

# VOLUME /var/www/html

# ENV WORDPRESS_VERSION 5.3.2
# ENV WORDPRESS_SHA1 fded476f112dbab14e3b5acddd2bcfa550e7b01b

# RUN set -ex; \
	# curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-5.3.2.tar.gz"; \
	# echo "fded476f112dbab14e3b5acddd2bcfa550e7b01b *wordpress.tar.gz" | sha1sum -c -; \
	# tar -xzf wordpress.tar.gz -C /usr/src/; \
	# rm wordpress.tar.gz; \
	# chown -R www-data:www-data /usr/src/wordpress

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
