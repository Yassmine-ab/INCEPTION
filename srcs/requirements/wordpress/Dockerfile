FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	php8.1-fpm \
	php8.1-mysql \
	php8.1-cli \
	php8.1-curl \
	php8.1-gd \
	php8.1-mbstring \
	php8.1-xml \
	php8.1-zip \
	php8.1-intl \
	php8.1-bcmath \
	curl \
	mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

# Configure le socket de php-fpm pour qu'il ecoute sur le port 9000 au lieu d'un socket file
RUN sed -i 's/listen = \/run\/php\/php8.1-fpm.sock/listen = 9000/g' /etc/php/8.1/fpm/pool.d/www.conf

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# Telecharge et installe WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Copie le script d'initialisation de WordPress
COPY tools/init-wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-wordpress.sh

EXPOSE 9000

# Lance le script d'initialisation de WordPress
CMD ["/usr/local/bin/init-wordpress.sh"]
