# 📘 Inception - Guide de Compréhension Détaillé

## 🎯 Objectif du Projet

Le projet Inception vous forme à l'**administration système** et à **Docker** en vous demandant de créer une infrastructure web complète containerisée. Vous devez comprendre et maîtriser :

1. La **containerisation** avec Docker
2. L'**orchestration** avec Docker Compose
3. La **sécurité** (SSL/TLS, gestion des secrets)
4. Les **architectures web modernes** (reverse proxy, séparation des services)
5. La **persistance des données** (volumes)
6. Les **réseaux Docker** (communication inter-containers)

---

## 🏗️ Architecture Expliquée

### Vue d'Ensemble

```
[Internet] 
    ↓ Port 443 (HTTPS)
[NGINX] ← Certificat SSL/TLS 1.2-1.3
    ↓ FastCGI (port 9000)
[WordPress + PHP-FPM]
    ↓ MySQL (port 3306)
[MariaDB]
```

### Pourquoi cette Architecture ?

#### 1. **Séparation des Responsabilités**
- **NGINX** : Gère les connexions HTTPS et sert de reverse proxy
- **WordPress** : Traite la logique métier (PHP)
- **MariaDB** : Stocke les données

#### 2. **Sécurité**
- Un seul point d'entrée (NGINX sur port 443)
- MariaDB et WordPress ne sont pas exposés directement
- Isolation via réseau Docker

#### 3. **Scalabilité**
- Chaque service peut être mis à l'échelle indépendamment
- Facile d'ajouter des services (cache, load balancer, etc.)

---

## 🐳 Docker - Concepts Clés

### Qu'est-ce qu'un Container ?

Un **container** est une unité d'exécution isolée qui contient :
- Une application
- Ses dépendances
- Un système de fichiers minimal

**Différence avec une VM** :
- Les containers **partagent** le kernel de l'hôte
- Plus légers et plus rapides que les VMs
- Démarrage en secondes vs minutes

### Dockerfile

Un **Dockerfile** est un fichier de recette qui décrit comment construire une image Docker.

**Exemple du Dockerfile NGINX** :
```dockerfile
FROM debian:bullseye        # Image de base
RUN apt-get update          # Installer les packages
COPY conf/nginx.conf /etc/  # Copier la config
CMD ["nginx", "-g", "daemon off;"]  # Commande au démarrage
```

**Chaque instruction crée une "layer"** (couche) dans l'image.

### Docker Compose

**Docker Compose** orchestre plusieurs containers :
- Définit les services dans un fichier YAML
- Gère les dépendances (qui démarre en premier)
- Configure les networks et volumes
- Lance tout avec une seule commande : `docker-compose up`

---

## 📦 Les Services en Détail

### 1. NGINX - Le Serveur Web

#### Rôle
NGINX est votre **point d'entrée unique**. Il :
1. Reçoit les requêtes HTTPS du navigateur
2. Décrypte le SSL/TLS
3. Transfère la requête à WordPress (FastCGI)
4. Renvoie la réponse au navigateur

#### Configuration Clé (`nginx.conf`)

```nginx
server {
    listen 443 ssl;
    ssl_protocols TLSv1.2 TLSv1.3;  # Versions modernes uniquement
    
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;  # Envoie à WordPress
        include fastcgi_params;
    }
}
```

#### FastCGI : Qu'est-ce que c'est ?

FastCGI est un **protocole** qui permet à NGINX de communiquer avec PHP-FPM :
- Plus rapide que CGI classique
- Garde PHP en mémoire (pas de redémarrage à chaque requête)
- Standard pour NGINX + PHP

#### SSL/TLS : Pourquoi 1.2 et 1.3 ?

| Version | Status | Raison |
|---------|--------|--------|
| TLS 1.0 | ❌ Obsolète | Vulnérabilités connues |
| TLS 1.1 | ❌ Obsolète | Vulnérabilités connues |
| TLS 1.2 | ✅ Moderne | Sécurisé, largement supporté |
| TLS 1.3 | ✅ Moderne | Plus rapide et plus sécurisé |

#### PID 1 : Le Processus Principal

Dans un container, le **PID 1** est crucial :
- C'est le premier processus lancé
- Si PID 1 s'arrête → le container s'arrête
- Doit tourner en **foreground** (pas daemon)

```bash
# ❌ Mauvais : NGINX en daemon (background)
nginx

# ✅ Bon : NGINX en foreground
nginx -g "daemon off;"
```

---

### 2. WordPress - L'Application

#### Rôle
WordPress est votre **CMS** (Content Management System) :
- Génère les pages web dynamiquement
- Communique avec MariaDB pour les données
- Traite les requêtes PHP via PHP-FPM

#### PHP-FPM : Fast Process Manager

**PHP-FPM** est un gestionnaire de processus PHP :
- Garde plusieurs processus PHP en mémoire
- Traite les requêtes en parallèle
- Plus efficace que mod_php (Apache)

```bash
# Configuration PHP-FPM
listen = 9000                    # Port d'écoute
pm = dynamic                     # Gestion dynamique des processus
pm.max_children = 5              # Maximum 5 processus enfants
```

#### WP-CLI : WordPress Command Line

**WP-CLI** est un outil en ligne de commande pour WordPress :

```bash
# Télécharger WordPress
wp core download --allow-root

# Créer la configuration
wp config create --dbname=wordpress --dbuser=wpuser --allow-root

# Installer WordPress
wp core install --url=https://yaabdall.42.fr --title="Mon Site" --admin_user=wpadmin --allow-root

# Créer un utilisateur
wp user create wpeditor editor@42.fr --role=editor --allow-root
```

**Pourquoi `--allow-root` ?**
- Par défaut, WP-CLI refuse de s'exécuter en tant que root
- Dans un container, on est souvent root
- `--allow-root` contourne cette protection

#### Variables d'Environnement

WordPress utilise ces variables pour se connecter à MariaDB :

```env
MYSQL_HOST=mariadb          # Nom du service (résolu par Docker)
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=secret
```

Dans `wp-config.php`, elles sont utilisées :
```php
define('DB_HOST', getenv('MYSQL_HOST'));
define('DB_NAME', getenv('MYSQL_DATABASE'));
```

---

### 3. MariaDB - La Base de Données

#### Rôle
MariaDB stocke toutes les données WordPress :
- Articles et pages
- Utilisateurs
- Commentaires
- Options et réglages

#### MariaDB vs MySQL

- **MariaDB** = Fork open-source de MySQL
- Compatible avec MySQL
- Souvent plus performant
- Choix standard pour WordPress

#### Initialisation de la Base

Script `init-db.sh` :
```bash
# Créer la base de données
mysql -e "CREATE DATABASE IF NOT EXISTS wordpress;"

# Créer l'utilisateur
mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'password';"

# Donner les permissions
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';"

# Appliquer les changements
mysql -e "FLUSH PRIVILEGES;"
```

**Pourquoi `'wpuser'@'%'` ?**
- `wpuser` = nom d'utilisateur
- `%` = peut se connecter depuis n'importe quelle IP
- Nécessaire car WordPress est dans un autre container

#### Configuration MariaDB

Fichier `50-server.cnf` :
```ini
[mysqld]
bind-address = 0.0.0.0        # Écoute sur toutes les interfaces
port = 3306
user = mysql
```

**Pourquoi `0.0.0.0` ?**
- Par défaut, MariaDB écoute sur `127.0.0.1` (localhost uniquement)
- Avec `0.0.0.0`, il écoute sur toutes les interfaces réseau
- Permet à WordPress (autre container) de se connecter

---

## 🔌 Docker Network - Communication

### Réseau Bridge

Un **réseau bridge** est un réseau virtuel Docker :
```yaml
networks:
  inception-network:
    driver: bridge
```

#### Comment ça marche ?

1. Docker crée une interface réseau virtuelle
2. Chaque container reçoit une IP privée (ex: 172.18.0.x)
3. Docker fournit un **DNS interne**
4. Les containers se réfèrent par leur **nom de service**

**Exemple** :
```yaml
services:
  wordpress:
    environment:
      MYSQL_HOST: mariadb  # ← Nom du service, pas d'IP !
  
  mariadb:
    # Docker résout "mariadb" en 172.18.0.2 (par exemple)
```

#### Test de Communication

```bash
# Depuis WordPress, ping MariaDB
docker exec wordpress ping -c 3 mariadb

# Tester le port MySQL
docker exec wordpress nc -zv mariadb 3306
```

### Pourquoi pas `network: host` ?

```yaml
# ❌ Interdit par le sujet
services:
  nginx:
    network_mode: host
```

**Problèmes avec `host`** :
- Pas d'isolation réseau
- Tous les ports sont exposés
- Conflit de ports possibles
- Mauvaise pratique Docker

### Pourquoi pas `--link` ?

```bash
# ❌ Ancienne méthode dépréciée
docker run --link mariadb wordpress
```

**Problèmes avec `--link`** :
- Fonctionnalité obsolète
- Remplacée par les réseaux bridge
- Moins flexible

---

## 💾 Volumes - Persistance des Données

### Pourquoi des Volumes ?

Sans volumes, **les données sont perdues** quand le container s'arrête.

```bash
# Sans volume
docker run wordpress
docker stop wordpress
docker rm wordpress
# ❌ Tous les fichiers WordPress sont perdus !

# Avec volume
docker run -v wordpress_data:/var/www/html wordpress
docker stop wordpress
docker rm wordpress
docker run -v wordpress_data:/var/www/html wordpress
# ✅ Les fichiers sont toujours là !
```

### Configuration des Volumes

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yaabdall/data/wordpress
```

**Explication** :
- `driver: local` = Volume local (sur l'hôte)
- `type: none` + `o: bind` = Bind mount (montage direct)
- `device` = Chemin sur l'hôte

### Bind Mount vs Volume Docker

| Type | Description | Exemple |
|------|-------------|---------|
| **Bind Mount** | Dossier de l'hôte monté dans le container | `/home/yaabdall/data:/var/www/html` |
| **Volume Docker** | Géré par Docker, dans `/var/lib/docker/volumes/` | `wordpress_data:/var/www/html` |

**Le sujet impose** d'utiliser `/home/login/data/` → donc bind mount.

### Que Contiennent les Volumes ?

#### Volume WordPress (`/var/www/html`)
```
wordpress/
├── index.php              # Point d'entrée WordPress
├── wp-admin/              # Interface d'administration
├── wp-content/            # Thèmes, plugins, uploads
│   ├── themes/
│   ├── plugins/
│   └── uploads/
├── wp-includes/           # Code core WordPress
└── wp-config.php          # Configuration
```

#### Volume MariaDB (`/var/lib/mysql`)
```
mariadb/
├── wordpress/             # Dossier de la base "wordpress"
│   ├── wp_posts.frm       # Table des articles
│   ├── wp_users.frm       # Table des utilisateurs
│   └── ...
├── mysql/                 # Base système
└── ib_logfile0            # Logs InnoDB
```

---

## 🔒 Sécurité - Bonnes Pratiques

### 1. Pas de Mots de Passe dans le Code

❌ **Mauvais** :
```dockerfile
ENV MYSQL_PASSWORD=secret123
```

✅ **Bon** :
```yaml
# Dans .env
MYSQL_PASSWORD=secret123

# Dans docker-compose.yml
env_file:
  - .env

# Dans .gitignore
.env
secrets/
```

### 2. Secrets Management

```
secrets/
├── db_root_password.txt    # Mot de passe root MariaDB
├── db_password.txt         # Mot de passe utilisateur MySQL
└── credentials.txt         # Autres identifiants
```

**Fichier `.gitignore`** :
```
secrets/
srcs/.env
*.log
```

### 3. Utilisateur Admin Non Standard

❌ **Interdit** :
- admin
- Admin
- administrator
- Administrator
- admin-123

✅ **Bon** :
- wpadmin
- siteadmin
- yaabdall-admin

**Pourquoi ?**
- "admin" est le nom testé en premier lors d'attaques par force brute
- Utiliser un nom personnalisé ajoute une couche de sécurité

### 4. Port 443 Uniquement

```yaml
# ✅ Bon : Seul NGINX exposé
services:
  nginx:
    ports:
      - "443:443"
  
  wordpress:
    # Pas de ports exposés
  
  mariadb:
    # Pas de ports exposés
```

**Avantages** :
- Surface d'attaque réduite
- Pas d'accès direct à WordPress ou MariaDB
- Tout passe par NGINX (reverse proxy)

---

## ⚙️ Docker Compose - Configuration Complète

### Fichier `docker-compose.yml` Expliqué

```yaml
version: '3.8'

services:
  # Service MariaDB
  mariadb:
    container_name: mariadb           # Nom du container
    build:
      context: ./requirements/mariadb # Dossier du Dockerfile
      dockerfile: Dockerfile          # Nom du Dockerfile
    image: mariadb:inception          # Nom de l'image construite
    volumes:
      - mariadb_data:/var/lib/mysql   # Volume pour persistance
    networks:
      - inception-network             # Réseau Docker
    env_file:
      - .env                          # Variables d'environnement
    restart: unless-stopped           # Redémarrage automatique
    healthcheck:                      # Vérification santé
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s                   # Tous les 10 secondes
      timeout: 5s
      retries: 5

  # Service WordPress
  wordpress:
    container_name: wordpress
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    image: wordpress:inception
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception-network
    env_file:
      - .env
    depends_on:                       # Dépendances
      mariadb:
        condition: service_healthy    # Attend le healthcheck de MariaDB
    restart: unless-stopped

  # Service NGINX
  nginx:
    container_name: nginx
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    image: nginx:inception
    volumes:
      - wordpress_data:/var/www/html  # Même volume que WordPress
    networks:
      - inception-network
    ports:
      - "443:443"                     # Seul port exposé
    env_file:
      - .env
    depends_on:
      - wordpress                     # Attend WordPress
    restart: unless-stopped

# Définition des volumes
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

# Définition du réseau
networks:
  inception-network:
    driver: bridge
```

### Ordre de Démarrage

Grâce à `depends_on` et `healthcheck` :

1. **MariaDB** démarre en premier
2. Healthcheck vérifie que MariaDB est prêt
3. **WordPress** démarre (car MariaDB est healthy)
4. **NGINX** démarre en dernier (car WordPress est prêt)

---

## 🛠️ Makefile - Automation

### Rôle du Makefile

Simplifier la gestion des containers :
```bash
make        # Au lieu de: docker-compose -f srcs/docker-compose.yml up -d --build
make down   # Au lieu de: docker-compose -f srcs/docker-compose.yml down
```

### Makefile Expliqué

```makefile
# Variables
COMPOSE_FILE = ./srcs/docker-compose.yml
DATA_PATH = /home/yaabdall/data

# Règle principale
all:
	@mkdir -p $(DATA_PATH)/wordpress    # Créer les dossiers
	@mkdir -p $(DATA_PATH)/mariadb
	@docker-compose -f $(COMPOSE_FILE) up -d --build  # Build et start

# Arrêter les services
down:
	@docker-compose -f $(COMPOSE_FILE) down

# Nettoyage complet
fclean: down
	@docker system prune -af --volumes  # Supprimer tout
	@sudo rm -rf $(DATA_PATH)/*         # Supprimer les données

# Rebuild complet
re: fclean all
```

**Options importantes** :
- `-d` = Detached mode (en arrière-plan)
- `--build` = Rebuild les images si nécessaire
- `-f` = Spécifier le fichier docker-compose.yml

---

## 📚 Résumé des Concepts

### Docker
- **Container** = Application isolée
- **Image** = Template pour créer des containers
- **Dockerfile** = Recette pour construire une image
- **Volume** = Persistance des données
- **Network** = Communication inter-containers
- **Docker Compose** = Orchestration multi-containers

### Architecture Web
- **Reverse Proxy** = NGINX redistribue les requêtes
- **FastCGI** = Protocole NGINX ↔ PHP-FPM
- **3-tiers** = Web / Application / Database

### Sécurité
- **TLS 1.2/1.3** = Chiffrement moderne
- **Secrets Management** = Pas de mots de passe en clair
- **Isolation** = Un seul port exposé (443)
- **Admin Non-Standard** = Nom personnalisé

### DevOps
- **Infrastructure as Code** = docker-compose.yml
- **Automation** = Makefile
- **Healthchecks** = Vérification automatique
- **Restart Policy** = Haute disponibilité

---

## 🎓 Questions pour Tester Votre Compréhension

1. Pourquoi utilise-t-on Docker au lieu d'installer directement sur l'hôte ?
2. Quelle est la différence entre une image et un container ?
3. Pourquoi NGINX est-il le seul service exposé ?
4. Comment WordPress communique-t-il avec MariaDB ?
5. Que se passe-t-il si MariaDB crashe ?
6. Pourquoi utiliser des volumes ?
7. Qu'est-ce que le PID 1 et pourquoi est-il important ?
8. Pourquoi TLS 1.0 et 1.1 sont-ils interdits ?
9. Quelle est la différence entre `network: host` et `network: bridge` ?
10. Pourquoi l'admin s'appelle `wpadmin` et non `admin` ?

---

Vous avez maintenant toutes les clés pour **comprendre et expliquer** votre projet Inception en détail ! 🚀
