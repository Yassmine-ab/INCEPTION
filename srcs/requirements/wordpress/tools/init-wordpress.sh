#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting WordPress initialization...${NC}"

# Wait for MariaDB to be ready
echo -e "${YELLOW}Waiting for MariaDB to be ready...${NC}"
while ! mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
	echo -e "${YELLOW}Waiting for database connection...${NC}"
	sleep 2
done
echo -e "${GREEN}MariaDB is ready!${NC}"

# Wait for Redis to be ready
echo -e "${YELLOW}Waiting for Redis to be ready...${NC}"
while ! nc -z redis 6379; do
	echo -e "${YELLOW}Waiting for Redis connection...${NC}"
	sleep 2
done
echo -e "${GREEN}Redis is ready!${NC}"

# Check if WordPress is already installed
if [ ! -f "/var/www/html/wp-config.php" ]; then
	echo -e "${YELLOW}WordPress not found. Installing...${NC}"
	
	# Download WordPress
	wp core download --allow-root
	
	# Create wp-config.php
	wp config create \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${MYSQL_PASSWORD}" \
		--dbhost="mariadb" \
		--allow-root
	
	# Add Redis configuration to wp-config.php
	wp config set WP_REDIS_HOST redis --allow-root
	wp config set WP_REDIS_PORT 6379 --raw --allow-root
	wp config set WP_CACHE true --raw --allow-root
	
	# Install WordPress
	wp core install \
		--url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--allow-root
	
	# Create additional user
	wp user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--role=editor \
		--user_pass="${WP_USER_PASSWORD}" \
		--allow-root
	
	# Install and activate Redis Object Cache plugin
	wp plugin install redis-cache --activate --allow-root
	wp redis enable --allow-root
	
	echo -e "${GREEN}WordPress installed successfully!${NC}"
else
	echo -e "${GREEN}WordPress already installed.${NC}"
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo -e "${GREEN}Starting PHP-FPM...${NC}"

# Start PHP-FPM in foreground mode
exec php-fpm7.4 -F
