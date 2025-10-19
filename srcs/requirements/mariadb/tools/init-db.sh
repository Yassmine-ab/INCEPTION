#!/bin/bash
set -e

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mysql_install_db --user=mysql --datadir=/var/lib/mysql

	mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
	pid="$!"

	for i in {30..0}; do
		if mysqladmin ping --silent; then
			break
		fi
		sleep 1
	done

	if [ "$i" = 0 ]; then
		echo "MariaDB failed to start"
		exit 1
	fi

	mysql -uroot << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

	mysqladmin -uroot shutdown
	wait "$pid"
fi

exec mysqld --user=mysql --datadir=/var/lib/mysql --console
