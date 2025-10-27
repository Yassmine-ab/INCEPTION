#!/bin/bash
set -e # Si une commande échoue, le script s'arrête immédiatement

mkdir -p /var/run/mysqld # Crée le dossier pour le socket de MariaDB s'il n'existe pas
chown -R mysql:mysql /var/run/mysqld # Donne les droits à l'utilisateur mysql

# Si le dossier mysql ou le fichier .initialized n'existe pas, la base de données n'a pas encore été initialisée
if [ ! -d "/var/lib/mysql/mysql" ] || [ ! -f /var/lib/mysql/.initialized ]; then

	rm -rf /var/lib/mysql/* # Supprime tout le contenu du dossier mysql s'il existe
	mysql_install_db --user=mysql --datadir=/var/lib/mysql # Initialise la base de données en créant le dossier mysql et les fichiers nécessaires
	mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking & # Démarre la base de données sans réseau le temps de l'initialisation
	pid="$!" # Récupère le PID du processus mysqld

# Essaie de se connecter à la base de données toutes les secondes (30 secondes)
	for i in {30..0}; do
		if mysqladmin ping --silent; then # Si la connexion réussit, la boucle s'arrête
			break
		fi
		sleep 1
	done

# Si la connexion n'a pas réussi après 30 secondes, le script s'arrête
	if [ "$i" = 0 ]; then
		echo "MariaDB failed to start"
		exit 1
	fi

# Exécute les commandes SQL dans le heredoc pour configurer la base de données
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
	mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown # Arrête la base de données qui avait été démarrée pour l'initialisation
	wait "$pid" # Attend que le processus mysqld se termine
	touch /var/lib/mysql/.initialized # Crée le fichier .initialized pour indiquer que l'initialisation est terminée (flag)
fi

# Démarre la base de données en mode console, remplaçant le processus actuel
exec mysqld --user=mysql --datadir=/var/lib/mysql --console
