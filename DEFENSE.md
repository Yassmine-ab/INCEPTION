# Inception - Guide de Défense (Partie Obligatoire)

## 🎯 Points Clés pour la Défense

### Architecture Globale
- **3 containers** : nginx, wordpress, mariadb
- **2 volumes** : wordpress_data, mariadb_data
- **1 network** : inception-network (bridge)
- **Tous les services** redémarrent automatiquement (`restart: unless-stopped`)

---

## 📋 Partie Obligatoire - Détails

### 1. NGINX

**Caractéristiques** :
- **Base** : Debian Bullseye
- **SSL/TLS** : 1.2 et 1.3 uniquement (pas de 1.0 ou 1.1)
- **Certificat** : Auto-signé avec OpenSSL
- **Port** : 443 (HTTPS uniquement)
- **Rôle** : Reverse proxy vers WordPress (FastCGI)
- **PID 1** : `nginx -g "daemon off;"`

**Questions possibles** :

**Q: Pourquoi TLS 1.2/1.3 uniquement ?**
- R: TLS 1.0 et 1.1 sont obsolètes et présentent des vulnérabilités de sécurité. Les versions 1.2 et 1.3 sont les standards modernes recommandés.

**Q: Comment avez-vous configuré le certificat SSL ?**
- R: Généré automatiquement dans le Dockerfile avec OpenSSL :
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=yaabdall.42.fr"
```

**Q: Pourquoi `daemon off;` ?**
- R: Pour que NGINX tourne en foreground et soit le PID 1. Si le processus se termine, le container s'arrête.

**Commandes de vérification** :
```bash
# Voir la configuration SSL
docker exec nginx cat /etc/nginx/nginx.conf | grep ssl_protocols

# Vérifier la version NGINX
docker exec nginx nginx -V

# Tester HTTPS
curl -k -I https://yaabdall.42.fr
```

---

### 2. WordPress

**Caractéristiques** :
- **Base** : Debian Bullseye
- **PHP** : 7.4-FPM (sans nginx)
- **WP-CLI** : Installation automatique de WordPress
- **Port** : 9000 (FastCGI, non exposé)
- **Utilisateurs** : 
  - Admin : `wpadmin` (pas "admin")
  - Éditeur : `wpeditor`
- **PID 1** : `php-fpm7.4 -F`

**Questions possibles** :

**Q: Pourquoi PHP-FPM et pas Apache/NGINX ?**
- R: Le sujet demande WordPress avec php-fpm uniquement, sans serveur web interne. NGINX se connecte à PHP-FPM via FastCGI.

**Q: Comment WordPress se connecte à MariaDB ?**
- R: Via des variables d'environnement définies dans `.env` et passées au container via docker-compose.

**Q: Pourquoi l'admin s'appelle `wpadmin` ?**
- R: Le sujet interdit d'utiliser "admin" ou "administrator" dans le nom de l'utilisateur administrateur pour des raisons de sécurité.

**Q: Comment avez-vous installé WordPress ?**
- R: Avec WP-CLI dans le script `init-wordpress.sh` :
```bash
wp core download --allow-root
wp config create --allow-root
wp core install --allow-root
wp user create --allow-root
```

**Commandes de vérification** :
```bash
# Liste des utilisateurs WordPress
docker exec wordpress wp user list --allow-root

# Version WordPress
docker exec wordpress wp core version --allow-root

# Plugins installés
docker exec wordpress wp plugin list --allow-root

# Vérifier PHP-FPM
docker exec wordpress ps aux | grep php-fpm
```

---

### 3. MariaDB

**Caractéristiques** :
- **Base** : Debian Bullseye
- **Version** : 10.5+
- **Port** : 3306 (non exposé, réseau interne)
- **Base de données** : wordpress
- **Utilisateurs** : root + wpuser
- **PID 1** : `mysqld --user=mysql`

**Questions possibles** :

**Q: Pourquoi MariaDB et pas MySQL ?**
- R: MariaDB est un fork open-source de MySQL, compatible et souvent plus performant. C'est un choix standard pour WordPress.

**Q: Comment les données persistent-elles ?**
- R: Via un volume Docker monté sur `/var/lib/mysql` et persisté dans `/home/yaabdall/data/mariadb` sur l'hôte.

**Q: Pourquoi le port 3306 n'est pas exposé ?**
- R: Pour la sécurité. MariaDB communique uniquement avec WordPress via le réseau Docker interne.

**Q: Comment avez-vous créé la base de données ?**
- R: Dans le script `init-db.sh` exécuté au démarrage du container :
```sql
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
```

**Commandes de vérification** :
```bash
# Test de connexion
docker exec mariadb mysqladmin ping -h localhost -uroot -p$MYSQL_ROOT_PASSWORD

# Liste des bases de données
docker exec mariadb mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"

# Liste des utilisateurs
docker exec mariadb mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT User, Host FROM mysql.user;"

# Tables WordPress
docker exec mariadb mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "USE wordpress; SHOW TABLES;"
```

---

### 4. Volumes

**Configuration** :
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yaabdall/data/wordpress
  
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yaabdall/data/mariadb
```

**Questions possibles** :

**Q: Pourquoi utiliser des volumes ?**
- R: Pour la persistance des données. Sans volumes, toutes les données sont perdues quand le container est supprimé.

**Q: Que contient le volume WordPress ?**
- R: Tous les fichiers du site WordPress : wp-admin, wp-content (thèmes, plugins, uploads), wp-includes, wp-config.php, etc.

**Q: Que contient le volume MariaDB ?**
- R: Les fichiers de la base de données MySQL (tables, index, logs).

**Q: Pourquoi `/home/yaabdall/data/` ?**
- R: Le sujet impose que les volumes soient dans `/home/login/data/` sur l'hôte.

**Commandes de vérification** :
```bash
# Lister les volumes
docker volume ls

# Inspecter un volume
docker volume inspect inception_wordpress_data

# Voir le contenu sur l'hôte
ls -la /home/yaabdall/data/wordpress
ls -la /home/yaabdall/data/mariadb

# Test de persistance
make down          # Arrêter les containers
ls -la /home/yaabdall/data/wordpress  # Les fichiers sont toujours là
make up            # Redémarrer
# Le site est intact avec toutes les données
```

---

### 5. Network

**Configuration** :
```yaml
networks:
  inception-network:
    driver: bridge
```

**Questions possibles** :

**Q: Qu'est-ce qu'un réseau Docker bridge ?**
- R: Un réseau virtuel isolé qui permet aux containers de communiquer entre eux via leurs noms de service.

**Q: Comment WordPress contacte-t-il MariaDB ?**
- R: Via le nom du service : `mariadb:3306`. Docker résout automatiquement le nom en adresse IP.

**Q: Pourquoi pas `network: host` ?**
- R: Le sujet l'interdit. `host` désactive l'isolation réseau, ce qui est contraire aux bonnes pratiques Docker.

**Q: Pourquoi pas `--link` ?**
- R: Le sujet l'interdit. C'est une fonctionnalité dépréciée de Docker. Les réseaux bridge sont la solution moderne.

**Commandes de vérification** :
```bash
# Lister les réseaux
docker network ls

# Inspecter le réseau
docker network inspect inception_inception-network

# Voir les containers connectés
docker network inspect inception_inception-network | grep -A 5 "Containers"

# Test de communication
docker exec wordpress ping -c 3 mariadb
docker exec wordpress nc -zv mariadb 3306
```

---

## 🔍 Points de Vérification Importants

### Sécurité
✅ Pas de mots de passe dans les Dockerfiles  
✅ Variables dans `.env`  
✅ Secrets dans `secrets/` (ignorés par git)  
✅ TLS 1.2/1.3 uniquement  
✅ Port 443 uniquement exposé

### Bonnes Pratiques Docker
✅ Pas de `tail -f`  
✅ Pas de boucles infinies (`while true`, `sleep infinity`)  
✅ Processus en foreground (PID 1)  
✅ Images de base : Debian Bullseye  
✅ Pas d'images pré-construites (sauf base OS)  
✅ Restart automatique (`unless-stopped`)

### Dockerfiles
✅ Un Dockerfile par service  
✅ Nom : `Dockerfile` (pas d'extension)  
✅ Appelés par docker-compose.yml  
✅ Images construites localement  
✅ Pas de tag `latest`

### Utilisateurs WordPress
✅ Utilisateur admin sans "admin" dans le nom  
✅ Au moins 2 utilisateurs (admin + éditeur)

---

## 🚀 Commandes de Démonstration

### Démarrage
```bash
make              # Build et start
docker ps         # Voir les 3 containers running
```

### Vérification des Services
```bash
# Test NGINX SSL
curl -k -I https://yaabdall.42.fr

# Test WordPress
docker exec wordpress wp core version --allow-root
docker exec wordpress wp user list --allow-root

# Test MariaDB
docker exec mariadb mysqladmin ping -h localhost -uroot -p$MYSQL_ROOT_PASSWORD

# Voir les logs
make logs
```

### Vérification des Volumes
```bash
ls -la /home/yaabdall/data/
docker volume ls
docker volume inspect inception_wordpress_data
```

### Vérification du Network
```bash
docker network ls
docker network inspect inception_inception-network
```

### Test de Redémarrage Automatique
```bash
docker stop nginx
sleep 5
docker ps | grep nginx
# nginx devrait être redémarré automatiquement
```

---

## 💡 Questions Fréquentes lors de la Défense

### "Pourquoi pas de docker-compose pull ?"
- **R:** Toutes les images sont construites localement à partir des Dockerfiles. Le sujet interdit d'utiliser des images pré-construites depuis Docker Hub (sauf les images de base comme Debian).

### "Comment gérez-vous les secrets ?"
- **R:** 
  - Variables d'environnement dans `srcs/.env`
  - Mots de passe sensibles dans `secrets/`
  - `.gitignore` pour ne pas versionner ces fichiers

### "Expliquez le PID 1"
- **R:** 
  - Premier processus du container
  - Si PID 1 meurt, le container s'arrête
  - Doit tourner en foreground (pas en daemon)
  - Exemples : `nginx -g "daemon off;"`, `php-fpm -F`, `mysqld`

### "Pourquoi TLS 1.2/1.3 uniquement ?"
- **R:** TLS 1.0 et 1.1 sont obsolètes et présentent des vulnérabilités connues. C'est une best practice de sécurité moderne.

### "Que se passe-t-il si MariaDB crashe ?"
- **R:** Le container redémarre automatiquement grâce à `restart: unless-stopped`. WordPress attend que MariaDB soit prêt grâce au healthcheck.

### "Pourquoi FastCGI au lieu de mod_php ?"
- **R:** 
  - Meilleure performance
  - Isolation entre web server et PHP
  - Standard moderne avec NGINX
  - Requis par le sujet (PHP-FPM)

---

## 📝 Checklist Finale

Avant la défense, vérifier :

- [ ] `/etc/hosts` contient `127.0.0.1 yaabdall.42.fr`
- [ ] Dossiers `/home/yaabdall/data/*` existent
- [ ] `make` démarre tous les services sans erreur
- [ ] https://yaabdall.42.fr est accessible
- [ ] WordPress admin accessible et fonctionnel
- [ ] 2 utilisateurs WordPress créés (wpadmin, wpeditor)
- [ ] Aucune image Docker pull depuis Docker Hub
- [ ] Pas de mots de passe dans les Dockerfiles
- [ ] `.env` et `secrets/` sont ignorés par git
- [ ] `docker ps` montre 3 containers running
- [ ] Les containers redémarrent après un stop
- [ ] Volumes persistent après `make down`

---

## 🎓 Points à Mentionner

1. **Architecture 3-tiers** : Web (NGINX) → Application (WordPress) → Database (MariaDB)
2. **Isolation** : Chaque service dans son propre container
3. **Persistance** : Volumes pour les données critiques
4. **Sécurité** : TLS moderne, pas d'exposition inutile, secrets gérés proprement
5. **Automation** : Makefile pour simplifier la gestion
6. **Best Practices** : Pas de hacks (tail -f), processus foreground, healthchecks

---

## 🔧 Modifications Possibles en Défense

Si on vous demande de faire une modification :

### Changer un port
```yaml
# Dans docker-compose.yml
services:
  nginx:
    ports:
      - "8443:443"  # Au lieu de 443:443
```

### Ajouter une variable d'environnement
```yaml
# Dans docker-compose.yml ou .env
environment:
  - NEW_VAR=value
```

### Modifier la configuration NGINX
```nginx
# Dans srcs/requirements/nginx/conf/nginx.conf
# Exemple: changer le server_name
server_name new-domain.42.fr;
```

Puis reconstruire :
```bash
make fclean
make
```

---

Bonne défense ! 🚀
