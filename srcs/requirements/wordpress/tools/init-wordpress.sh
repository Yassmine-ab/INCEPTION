#!/bin/bash

# Exit immediatement si une commande echoue
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting WordPress initialization...${NC}"

# Attend que MariaDB soit prêt
echo -e "${YELLOW}Waiting for MariaDB to be ready...${NC}"
while ! mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
	echo -e "${YELLOW}Waiting for database connection...${NC}"
	sleep 1
done
echo -e "${GREEN}MariaDB is ready!${NC}"

# Vérifie si WordPress est déjà installé
if [ ! -f "/var/www/html/wp-config.php" ]; then
	echo -e "${YELLOW}WordPress not found. Installing...${NC}"

	wp core download --allow-root
	
	wp config create \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${MYSQL_PASSWORD}" \
		--dbhost="mariadb" \
		--allow-root
	
	wp core install \
		--url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--allow-root
	
	wp user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--role=editor \
		--user_pass="${WP_USER_PASSWORD}" \
		--allow-root
	
	echo -e "${GREEN}WordPress installed successfully!${NC}"
else
	echo -e "${GREEN}WordPress already installed.${NC}"
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo -e "${GREEN}Starting WordPress...${NC}"

# Lance PHP-FPM en avant-plan pour que le conteneur reste actif
exec php-fpm8.2 -F
