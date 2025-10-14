# 📋 Projet Inception - Guide Complet (Partie Obligatoire)

## 🎯 Vue d'Ensemble

Le projet Inception consiste à créer une **infrastructure web complète** en utilisant Docker et Docker Compose. L'objectif est de containeriser plusieurs services et de les faire communiquer ensemble via un réseau Docker isolé.

---

## ✅ Services Implémentés (Mandatory)

| # | Service | Port | Image de base | Rôle |
|---|---------|------|---------------|------|
| 1 | **NGINX** | 443 | Debian Bullseye | Reverse proxy HTTPS, point d'entrée unique |
| 2 | **WordPress** | 9000 (interne) | Debian Bullseye | CMS avec PHP-FPM 7.4 |
| 3 | **MariaDB** | 3306 (interne) | Debian Bullseye | Base de données MySQL |

---

## 🏗️ Architecture

```
Internet (HTTPS:443)
        │
        ▼
   ┌─────────┐
   │  NGINX  │  ← Point d'entrée unique (SSL/TLS 1.2-1.3)
   └────┬────┘
        │ FastCGI
        ▼
┌───────────────┐
│   WordPress   │  ← PHP-FPM 7.4 (pas de NGINX interne)
└───────┬───────┘
        │ MySQL
        ▼
┌───────────────┐
│   MariaDB     │  ← Base de données
└───────────────┘

Network: inception-network (bridge)
Volumes: wordpress_data, mariadb_data
```

---

## 📁 Structure du Projet

```
inception/
├── Makefile                          # Gestion Docker Compose
├── secrets/                          # Mots de passe (non versionnés)
│   ├── credentials.txt
│   ├── db_root_password.txt
│   └── db_password.txt
│
└── srcs/
    ├── .env                          # Variables d'environnement
    ├── docker-compose.yml            # Configuration des services
    │
    └── requirements/
        ├── nginx/                    # Service NGINX
        │   ├── Dockerfile
        │   └── conf/nginx.conf
        │
        ├── wordpress/                # Service WordPress
        │   ├── Dockerfile
        │   └── tools/init-wordpress.sh
        │
        └── mariadb/                  # Service MariaDB
            ├── Dockerfile
            ├── conf/50-server.cnf
            └── tools/init-db.sh
```

---

## 🔧 Configuration Détaillée

### 1. NGINX

**Rôle** : Serveur web HTTPS, reverse proxy vers WordPress

**Caractéristiques** :
- SSL/TLS 1.2 et 1.3 uniquement
- Certificat auto-signé (généré au build)
- FastCGI vers WordPress (port 9000)
- Seul port exposé : 443

**Dockerfile** :
- Base : `debian:bullseye`
- Packages : `nginx`, `openssl`
- Configuration : `/etc/nginx/nginx.conf`
- Commande : `nginx -g "daemon off;"`

**Points clés** :
- Pas de TLS 1.0 ou 1.1
- Pas de `tail -f` ou boucle infinie
- PID 1 = nginx en foreground

### 2. WordPress

**Rôle** : CMS avec PHP-FPM

**Caractéristiques** :
- PHP-FPM 7.4 (sans NGINX)
- WP-CLI pour installation automatique
- 2 utilisateurs : admin (`wpadmin`) + éditeur (`wpeditor`)
- Connexion à MariaDB via variables d'environnement

**Dockerfile** :
- Base : `debian:bullseye`
- Packages : `php7.4-fpm`, `php7.4-mysql`, `curl`
- WP-CLI installé
- Script d'init : `init-wordpress.sh`
- Commande : `php-fpm7.4 -F`

**Points clés** :
- Admin ne contient pas "admin" ou "administrator"
- Volume persistant sur `/var/www/html`
- Attend MariaDB avant de démarrer (healthcheck)

### 3. MariaDB

**Rôle** : Base de données MySQL

**Caractéristiques** :
- Base de données `wordpress`
- 2 utilisateurs : root + wpuser
- Configuration dans `50-server.cnf`
- Volume persistant

**Dockerfile** :
- Base : `debian:bullseye`
- Package : `mariadb-server`
- Script d'init : `init-db.sh`
- Commande : `mysqld --user=mysql`

**Points clés** :
- Port 3306 non exposé (réseau interne)
- Healthcheck pour vérifier la disponibilité
- Volume monté sur `/var/lib/mysql`

---

## 📦 Volumes

Les volumes sont montés sur l'hôte dans `/home/yaabdall/data/` :

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

**Avantages** :
- Persistance des données
- Backup facile
- Survie après `docker-compose down`

---

## 🌐 Network

```yaml
networks:
  inception-network:
    driver: bridge
```

**Caractéristiques** :
- Réseau isolé
- Communication inter-containers
- Pas de `network: host`
- Pas de `--link` ou `links:`

---

## 🔐 Variables d'Environnement

Fichier `srcs/.env` :

```env
# Domain
DOMAIN_NAME=yaabdall.42.fr

# MySQL/MariaDB
MYSQL_ROOT_PASSWORD=root_secure_password_123
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wpuser_secure_password_456

# WordPress
WP_ADMIN_USER=wpadmin
WP_ADMIN_PASSWORD=admin_secure_password_789
WP_ADMIN_EMAIL=yaabdall@student.42.fr
WP_TITLE=Inception Website
WP_URL=https://yaabdall.42.fr

# Additional User
WP_USER=wpeditor
WP_USER_PASSWORD=editor_secure_password_012
WP_USER_EMAIL=editor@student.42.fr
```

---

## ⚡ Makefile

```makefile
all:
    @mkdir -p /home/yaabdall/data/{wordpress,mariadb}
    @docker-compose -f srcs/docker-compose.yml up -d --build

down:
    @docker-compose -f srcs/docker-compose.yml down

clean:
    @docker system prune -af

fclean: down
    @docker system prune -af --volumes
    @sudo rm -rf /home/yaabdall/data/{wordpress,mariadb}

re: fclean all
```

---

## 🚀 Utilisation

### Démarrage
```bash
make              # Build et start
```

### Vérification
```bash
docker ps         # 3 containers running
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Accès
- **WordPress** : https://yaabdall.42.fr
- **Admin** : https://yaabdall.42.fr/wp-admin

### Nettoyage
```bash
make clean        # Containers et networks
make fclean       # Tout + volumes + data
```

---

## ✅ Checklist de Validation

### Docker Compose
- [x] Fichier `docker-compose.yml` dans `srcs/`
- [x] Services : nginx, wordpress, mariadb
- [x] Network défini
- [x] Volumes définis
- [x] Variables d'environnement dans `.env`

### Dockerfiles
- [x] Un Dockerfile par service
- [x] Nom : `Dockerfile` (pas d'extension)
- [x] Images de base : Debian Bullseye
- [x] Pas d'images pré-construites (sauf base OS)
- [x] Pas de tag `latest`

### NGINX
- [x] Port 443 exposé
- [x] SSL/TLS 1.2 et 1.3 uniquement
- [x] Certificat généré automatiquement
- [x] Reverse proxy vers WordPress
- [x] Pas de `tail -f`

### WordPress
- [x] PHP-FPM sans NGINX
- [x] WP-CLI pour installation
- [x] 2 utilisateurs configurés
- [x] Admin sans "admin" dans le nom
- [x] Volume persistant

### MariaDB
- [x] Base de données `wordpress`
- [x] 2 utilisateurs (root + wpuser)
- [x] Port non exposé
- [x] Volume persistant
- [x] Healthcheck

### Sécurité
- [x] Pas de mots de passe dans Dockerfiles
- [x] Variables dans `.env`
- [x] `.env` et `secrets/` dans `.gitignore`
- [x] NGINX seul point d'entrée

### Volumes
- [x] 2 volumes : wordpress_data, mariadb_data
- [x] Montés dans `/home/yaabdall/data/`
- [x] Persistance garantie

### Network
- [x] Network `inception-network` créé
- [x] Type : bridge
- [x] Pas de `network: host`
- [x] Pas de `--link`

### Restart Policy
- [x] `restart: unless-stopped` sur tous les services

### Makefile
- [x] À la racine du projet
- [x] Build avec `docker-compose`
- [x] Création des dossiers data
- [x] Règles : all, clean, fclean, re

---

## 🎓 Concepts à Expliquer

### 1. Docker vs VM
- Docker = Containerisation (partage le kernel)
- VM = Virtualisation (kernel isolé)
- Plus léger, plus rapide

### 2. PID 1
- Premier processus du container
- Si PID 1 meurt → container s'arrête
- Doit tourner en foreground (pas daemon)

### 3. Volumes
- Persistance des données
- Survie après suppression du container
- Backup facilité

### 4. Network Bridge
- Réseau virtuel isolé
- Communication inter-containers
- Résolution DNS automatique

### 5. FastCGI
- Protocole de communication
- NGINX ↔ PHP-FPM
- Plus performant que CGI classique

### 6. SSL/TLS
- Chiffrement HTTPS
- TLS 1.2/1.3 = standards modernes
- Certificat auto-signé pour dev local

---

## 🐛 Problèmes Courants

### Port 443 déjà utilisé
```bash
sudo lsof -i :443
sudo kill -9 <PID>
```

### Permissions sur /home/yaabdall/data
```bash
sudo chown -R $USER:$USER /home/yaabdall/data
sudo chmod -R 755 /home/yaabdall/data
```

### WordPress ne se connecte pas à MariaDB
- Vérifier le healthcheck de MariaDB
- Vérifier les variables d'environnement
- Vérifier les logs : `docker logs mariadb`

### NGINX 502 Bad Gateway
- WordPress pas démarré
- PHP-FPM pas lancé
- Vérifier : `docker logs wordpress`

---

## 📚 Documentation de Référence

- [Sujet Inception](./en.subject.pdf)
- [Docker Docs](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [NGINX Config](https://nginx.org/en/docs/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB Docs](https://mariadb.com/kb/en/)

---

## 🎯 Résultat Final

**✅ PROJET PRÊT POUR LA DÉFENSE**

- 3 services containerisés
- Architecture conforme au sujet
- Volumes persistants
- Network isolé
- Sécurité respectée
- Documentation complète

---

*Projet Inception - École 42 - Octobre 2025*
