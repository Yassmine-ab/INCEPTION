#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting MariaDB initialization...${NC}"

# Create necessary directories
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql

# Initialize database if not already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo -e "${YELLOW}Initializing MariaDB data directory...${NC}"
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MariaDB temporarily to configure it
echo -e "${YELLOW}Starting MariaDB temporarily...${NC}"
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
pid="$!"

# Wait for MariaDB to start
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

# Configure MariaDB
echo -e "${YELLOW}Configuring MariaDB...${NC}"

mysql << EOF
-- Secure installation
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create user
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
EOF

echo -e "${GREEN}MariaDB configured successfully${NC}"

# Shutdown temporary MariaDB instance
echo -e "${YELLOW}Shutting down temporary MariaDB instance...${NC}"
mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown
wait "$pid"

echo -e "${GREEN}Starting MariaDB in production mode...${NC}"

# Start MariaDB in production mode
exec mysqld --user=mysql --datadir=/var/lib/mysql --console
