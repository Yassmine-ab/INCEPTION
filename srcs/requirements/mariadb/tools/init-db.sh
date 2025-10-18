#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting MariaDB initialization...${NC}"

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo -e "${YELLOW}Initializing MariaDB data directory...${NC}"
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Lance MariaDB temporairement pour la configuration
echo -e "${YELLOW}Starting MariaDB temporarily...${NC}"
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
pid="$!"

echo -e "${YELLOW}Waiting for MariaDB to start...${NC}"
for i in {30..0}; do
	if mysqladmin ping --silent; then
		break
	fi
	echo -e "${YELLOW}Waiting for MariaDB... $i${NC}"
	sleep 1
done

if [ "$i" = 0 ]; then
	echo -e "${RED}MariaDB failed to start${NC}"
	exit 1
fi

echo -e "${GREEN}MariaDB started successfully${NC}"

echo -e "${YELLOW}Configuring MariaDB...${NC}"

mysql << EOF
-- Definit le mot de passe root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Creee la base de donnees
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Creee l'utilisateur et lui attribue les privileges
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Applique les modifications
FLUSH PRIVILEGES;
EOF

echo -e "${GREEN}MariaDB configured successfully${NC}"

# Arrete MariaDB temporairement
echo -e "${YELLOW}Shutting down temporary MariaDB instance...${NC}"
mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown
wait "$pid"

echo -e "${GREEN}Starting MariaDB in production mode...${NC}"

# Lance MariaDB en avant-plan pour que le conteneur reste actif
exec mysqld --user=mysql --datadir=/var/lib/mysql --console
