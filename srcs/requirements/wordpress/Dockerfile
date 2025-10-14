FROM debian:bullseye

RUN apt-get update && apt-get install -y \
	php7.4-fpm \
	php7.4-mysql \
	php7.4-cli \
	php7.4-curl \
	php7.4-gd \
	php7.4-mbstring \
	php7.4-xml \
	php7.4-zip \
	php7.4-intl \
	php7.4-bcmath \
	curl \
	mariadb-client \
	netcat \
	&& rm -rf /var/lib/apt/lists/*

# Configure PHP-FPM to listen on port 9000
RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/g' /etc/php/7.4/fpm/pool.d/www.conf

# Create WordPress directory
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# Download and install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Copy initialization script
COPY tools/init-wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-wordpress.sh

# Create PHP-FPM directory
RUN mkdir -p /run/php

# Expose PHP-FPM port
EXPOSE 9000

# Run initialization script
CMD ["/usr/local/bin/init-wordpress.sh"]
