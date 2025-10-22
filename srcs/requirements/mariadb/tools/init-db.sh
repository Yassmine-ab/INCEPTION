#!/bin/bash
set -e

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ] || [ ! -f /var/lib/mysql/.initialized ]; then

	rm -rf /var/lib/mysql/*
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
	mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
	pid="$!"

	for i in {30..0}; do
		if mysqladmin ping --silent; then
			break
		fi
		echo 'MySQL init process in progress...'
		sleep 1
	done

	if [ "$i" = 0 ]; then
		echo "MariaDB failed to start"
		exit 1
	fi

	mysql -uroot << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
DROP USER IF EXISTS '${MYSQL_USER}'@'%';
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

	echo "=== Shutting down temporary instance ==="
	mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
	wait "$pid"
	touch /var/lib/mysql/.initialized
	echo "=== MariaDB initialization complete ==="
fi

echo "=== Starting MariaDB server ==="
exec mysqld --user=mysql --datadir=/var/lib/mysql --console
