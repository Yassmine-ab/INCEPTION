# Inception# Inception



Projet d'administration système utilisant Docker pour créer une infrastructure web complète avec NGINX, WordPress et MariaDB.Projet d'administration système utilisant Docker pour créer une infrastructure web complète avec NGINX, WordPress, MariaDB et 5 services bonus.



## 📋 Description## 📋 Description



Ce projet configure une infrastructure Docker composée de **3 services obligatoires** :Ce projet configure une infrastructure Docker composée de :



- **NGINX** : Serveur web avec SSL/TLS (port 443)### Services Obligatoires

- **WordPress** : CMS avec PHP-FPM 7.4- **NGINX** : Serveur web avec SSL/TLS (port 443)

- **MariaDB** : Base de données MySQL- **WordPress** : CMS avec PHP-FPM 7.4

- **MariaDB** : Base de données MySQL

## 🏗️ Architecture

### Services Bonus ⭐

```- **Redis** : Cache en mémoire pour optimiser WordPress

┌─────────────────────────────────────────┐- **FTP Server** : Serveur vsftpd pour accéder au volume WordPress

│         Internet (Port 443 HTTPS)       │- **Site Statique** : Portfolio HTML/CSS/JS (pas de PHP)

└──────────────────┬──────────────────────┘- **Adminer** : Interface web de gestion MySQL

                   │- **Portainer** : Interface de gestion et monitoring Docker

                   │ HTTPS/TLS 1.2-1.3

                   │## 🏗️ Architecture

        ┌──────────▼──────────┐

        │                     │```

        │       NGINX         │┌─────────────────────────────────────────┐

        │   SSL/TLS 1.2/1.3   ││      Internet (Ports 443, 8080-9000)    │

        │   (Port 443)        │└──────────────────┬──────────────────────┘

        │                     │                   │

        └──────────┬──────────┘        ┌──────────┴──────────┐

                   │        │                     │

                   │ FastCGI (Port 9000)   HTTPS (443)          HTTP (8080-9000)

                   │        │                     │

        ┌──────────▼──────────┐        ▼                     ▼

        │                     │┌───────────────┐     ┌───────────────┐

        │     WordPress       ││     NGINX     │     │    Adminer    │

        │    PHP-FPM 7.4      ││  SSL/TLS 1.3  │     │  Portainer    │

        │                     │└───────┬───────┘     │  Static Site  │

        └──────────┬──────────┘        │             └───────────────┘

                   │        │ FastCGI

                   │ MySQL Protocol (Port 3306)        ▼

                   │┌───────────────┐

        ┌──────────▼──────────┐│   WordPress   │◄────┐

        │                     ││  PHP-FPM 7.4  │     │

        │      MariaDB        │└───┬───────┬───┘     │

        │     (Database)      │    │       │         │

        │                     │    │       └─────────┤

        └─────────────────────┘    │         Redis   │ FTP (21)

```    │        (Cache)  │

    ▼                 │

## 📁 Structure du projet┌───────────────┐     │

│   MariaDB     │◄────┘

```│  (Database)   │

.└───────────────┘

├── Makefile                      # Commandes de gestion du projet```

├── secrets/                      # Fichiers de secrets (ignorés par git)

│   ├── credentials.txt## 📁 Structure du projet

│   ├── db_password.txt

│   └── db_root_password.txt```

└── srcs/.

    ├── .env                      # Variables d'environnement├── Makefile                      # Commandes de gestion du projet

    ├── docker-compose.yml        # Configuration Docker Compose├── secrets/                      # Fichiers de secrets (ignorés par git)

    └── requirements/│   ├── credentials.txt

        ├── mariadb/              # Service MariaDB│   ├── db_password.txt

        │   ├── Dockerfile│   └── db_root_password.txt

        │   ├── conf/└── srcs/

        │   │   └── 50-server.cnf    ├── .env                      # Variables d'environnement

        │   └── tools/    ├── docker-compose.yml        # Configuration Docker Compose

        │       └── init-db.sh    └── requirements/

        ├── nginx/                # Service NGINX        ├── mariadb/              # Service MariaDB

        │   ├── Dockerfile        │   ├── Dockerfile

        │   └── conf/        │   ├── conf/

        │       └── nginx.conf        │   └── tools/

        └── wordpress/            # Service WordPress        ├── nginx/                # Service NGINX

            ├── Dockerfile        │   ├── Dockerfile

            └── tools/        │   └── conf/

                └── init-wordpress.sh        ├── wordpress/            # Service WordPress

```        │   ├── Dockerfile

        │   └── tools/

## 🚀 Installation        └── bonus/                # Services bonus

            ├── redis/            # Cache Redis

### Prérequis            ├── ftp/              # Serveur FTP

            ├── adminer/          # Interface MySQL

- Docker            ├── website/          # Site statique

- Docker Compose            └── portainer/        # Gestion Docker

- Système Linux (VM recommandée)```



### Configuration initiale## 🚀 Installation



1. **Configurer le fichier hosts**### Prérequis



   Ajoutez votre domaine au fichier `/etc/hosts` :- Docker

   ```bash- Docker Compose

   sudo nano /etc/hosts- Système Linux (VM recommandée)

   ```

   ### Configuration initiale

   Ajoutez cette ligne :

   ```1. **Configurer le fichier hosts**

   127.0.0.1 yaabdall.42.fr

   ```   Ajoutez votre domaine au fichier `/etc/hosts` :

   ```bash

2. **Configurer les variables d'environnement**   sudo nano /etc/hosts

   ```

   Le fichier `srcs/.env` contient toutes les variables nécessaires. Modifiez-les selon vos besoins :   

   - Domaine : `DOMAIN_NAME`   Ajoutez cette ligne :

   - Identifiants MySQL   ```

   - Identifiants WordPress   127.0.0.1 yaabdall.42.fr

   ```

3. **Créer les dossiers de données**

2. **Configurer les variables d'environnement**

   Les volumes Docker seront montés dans `/home/yaabdall/data/` :

   ```bash   Le fichier `srcs/.env` contient toutes les variables nécessaires. Modifiez-les selon vos besoins :

   mkdir -p /home/yaabdall/data/wordpress   - Domaine : `DOMAIN_NAME`

   mkdir -p /home/yaabdall/data/mariadb   - Identifiants MySQL

   ```   - Identifiants WordPress

   - Identifiants FTP

### Lancement du projet

3. **Créer les dossiers de données**

```bash

# Construire et démarrer tous les services   Les volumes Docker seront montés dans `/home/yaabdall/data/` :

make   ```bash

   mkdir -p /home/yaabdall/data/wordpress

# Ou simplement   mkdir -p /home/yaabdall/data/mariadb

make all   mkdir -p /home/yaabdall/data/portainer

```   ```



## 🎮 Commandes disponibles### Lancement du projet



| Commande | Description |```bash

|----------|-------------|# Construire et démarrer tous les services

| `make` ou `make all` | Construit et démarre tous les services |make

| `make up` | Démarre les services (sans rebuild) |

| `make down` | Arrête tous les services |# Ou simplement

| `make stop` | Met en pause les services |make all

| `make start` | Reprend les services |```

| `make status` | Affiche l'état des services |

| `make logs` | Affiche les logs en temps réel |## 🎮 Commandes disponibles

| `make clean` | Arrête et supprime les conteneurs/réseaux |

| `make fclean` | Nettoyage complet (conteneurs/volumes/données) || Commande | Description |

| `make re` | Reconstruit tout depuis zéro ||----------|-------------|

| `make help` | Affiche l'aide || `make` ou `make all` | Construit et démarre tous les services |

| `make up` | Démarre les services (sans rebuild) |

## 🌐 Accès aux services| `make down` | Arrête tous les services |

| `make stop` | Met en pause les services |

Une fois les services démarrés :| `make start` | Reprend les services |

| `make status` | Affiche l'état des services |

- **Site WordPress** : https://yaabdall.42.fr| `make logs` | Affiche les logs en temps réel |

- **Admin WordPress** : https://yaabdall.42.fr/wp-admin| `make clean` | Arrête et supprime les conteneurs/réseaux |

| `make fclean` | Nettoyage complet (conteneurs/volumes/données) |

### Identifiants par défaut| `make re` | Reconstruit tout depuis zéro |

| `make help` | Affiche l'aide |

**Administrateur WordPress :**

- Username : `wpadmin`## 🌐 Accès aux services

- Password : `admin_secure_password_789`

- Email : `yaabdall@student.42.fr`Une fois les services démarrés :



**Éditeur WordPress :**### Services Principaux

- Username : `wpeditor`- **Site WordPress** : https://yaabdall.42.fr

- Password : `editor_secure_password_012`- **Admin WordPress** : https://yaabdall.42.fr/wp-admin

- Email : `editor@student.42.fr`

### Services Bonus

**Base de données :**- **Adminer** (MySQL Manager) : https://yaabdall.42.fr:8080

- Database : `wordpress`- **Site Statique** (Portfolio) : http://yaabdall.42.fr:8081

- User : `wpuser`- **Portainer** (Docker UI) : https://yaabdall.42.fr:9000

- Password : `wpuser_secure_password_456`- **FTP Server** : Port 21 (utilisez un client FTP)

- Root Password : `root_secure_password_123`

### Identifiants par défaut

⚠️ **Important** : Changez tous ces mots de passe dans le fichier `srcs/.env` avant le déploiement !

**Administrateur WordPress :**

## 🔒 Sécurité- Username : `wpadmin`

- Password : `admin_secure_password_789`

- Certificat SSL auto-signé généré automatiquement- Email : `yaabdall@student.42.fr`

- TLS 1.2 et 1.3 uniquement

- Mots de passe stockés dans des fichiers séparés (non versionnés)**Éditeur WordPress :**

- Utilisateur admin avec un nom non standard (`wpadmin` et non `admin`)- Username : `wpeditor`

- Connexion MariaDB limitée au réseau Docker interne- Password : `editor_secure_password_012`

- Aucun port exposé sauf le 443 (HTTPS)- Email : `editor@student.42.fr`



## 🔧 Configuration Technique**Base de données :**

- Database : `wordpress`

### Services- User : `wpuser`

- Password : `wpuser_secure_password_456`

| Service | Port | Rôle | Image de base |- Root Password : `root_secure_password_123`

|---------|------|------|---------------|

| **NGINX** | 443 | Reverse proxy HTTPS, point d'entrée unique | Debian Bullseye |**FTP :**

| **WordPress** | 9000 (interne) | CMS avec PHP-FPM | Debian Bullseye |- User : `ftpuser`

| **MariaDB** | 3306 (interne) | Base de données MySQL | Debian Bullseye |- Password : `ftp_secure_password_345`

- Host : `yaabdall.42.fr` ou `localhost`

### Volumes Persistants- Port : `21`



```⚠️ **Important** : Changez tous ces mots de passe dans le fichier `srcs/.env` avant le déploiement !

/home/yaabdall/data/

├── wordpress/      → Fichiers du site WordPress## 🔒 Sécurité

└── mariadb/        → Base de données MariaDB

```- Certificat SSL auto-signé généré automatiquement

- TLS 1.2 et 1.3 uniquement

### Network- Mots de passe stockés dans des fichiers séparés (non versionnés)

- Utilisateur admin avec un nom non standard

- **Nom** : inception-network- Connexion MariaDB limitée au réseau Docker

- **Type** : bridge- Redis sans authentification (réseau interne uniquement)

- **Isolation** : Réseau interne Docker uniquement- FTP avec authentification utilisateur



### Caractéristiques Docker## ⭐ Services Bonus - Détails



- ✅ Images construites localement (pas de pull depuis Docker Hub)### 1. Redis Cache

- ✅ Dockerfiles personnalisés pour chaque service**Port** : 6379 (interne)  

- ✅ Restart automatique des containers (`unless-stopped`)**Utilité** : Cache en mémoire pour accélérer WordPress. Réduit les requêtes à la base de données.  

- ✅ Pas de commandes infinies (`tail -f`, `sleep infinity`, etc.)**Plugin WordPress** : Redis Object Cache (installé automatiquement)

- ✅ Processus en foreground (PID 1)

- ✅ Healthcheck sur MariaDB### 2. FTP Server (vsftpd)

**Ports** : 21, 21000-21010  

## 🐛 Dépannage**Utilité** : Permet de gérer les fichiers WordPress via FTP  

**Accès** : Utilisez FileZilla ou tout client FTP avec les identifiants FTP

### Les services ne démarrent pas

### 3. Site Statique

```bash**Port** : 8081  

# Vérifier les logs**Utilité** : Portfolio / site vitrine en HTML/CSS/JS pur (pas de PHP)  

make logs**Technologie** : NGINX servant des fichiers statiques



# Vérifier l'état des conteneurs### 4. Adminer

docker ps -a**Port** : 8080  

**Utilité** : Interface web légère pour gérer MariaDB  

# Vérifier les volumes**Alternative** : Plus léger que phpMyAdmin  

docker volume ls**Connexion** : Utilisez les identifiants MySQL/MariaDB

```

### 5. Portainer

### Certificat SSL non reconnu**Port** : 9000  

**Utilité** : Interface graphique pour gérer vos containers Docker  

Le certificat est auto-signé, votre navigateur affichera un avertissement. C'est normal pour le développement local. Cliquez sur "Avancé" puis "Accepter le risque" pour continuer.**Fonctionnalités** : Visualisation, logs, statistiques, gestion des images/volumes/réseaux



### Erreur de permissions## 🐛 Dépannage



```bash### Les services ne démarrent pas

# Vérifier les permissions des dossiers de données

sudo chown -R $USER:$USER /home/yaabdall/data```bash

sudo chmod -R 755 /home/yaabdall/data# Vérifier les logs

```make logs



### Réinitialiser complètement le projet# Vérifier l'état des conteneurs

docker ps -a

```bash

make fclean# Vérifier les volumes

makedocker volume ls

``````



## 🎯 Checklist de validation du projet### Certificat SSL non reconnu



### Partie Obligatoire (Mandatory)Le certificat est auto-signé, votre navigateur affichera un avertissement. C'est normal pour le développement local. Cliquez sur "Avancé" puis "Accepter le risque" pour continuer.

- [x] NGINX avec TLS 1.2/1.3 uniquement

- [x] WordPress + PHP-FPM (sans NGINX)### Vérifier que Redis fonctionne

- [x] MariaDB (sans NGINX)

- [x] 2 volumes (WordPress + MariaDB)```bash

- [x] Network Docker (bridge)# Se connecter au container WordPress

- [x] Restart automatique des containersdocker exec -it wordpress bash

- [x] Pas de `tail -f` ou boucles infinies

- [x] 2 utilisateurs WordPress (dont 1 admin sans "admin" dans le nom)# Vérifier la connexion Redis

- [x] Domaine login.42.fr pointant vers l'IP localewp redis status --allow-root

- [x] Variables d'environnement dans .env

- [x] Secrets non présents dans les Dockerfiles# Tester le cache

- [x] NGINX seul point d'entrée (port 443)wp redis enable --allow-root

- [x] Images construites localement (pas de pull Docker Hub)```

- [x] Dockerfiles appelés par docker-compose.yml

- [x] Makefile à la racine du projet### Accéder au FTP



## 📊 Résumé des ports```bash

# En ligne de commande

| Service | Port(s) | Protocole | Accès |ftp yaabdall.42.fr

|---------|---------|-----------|-------|# Username: ftpuser

| NGINX | 443 | HTTPS | Public (seul port exposé) |# Password: ftp_secure_password_345

| WordPress | 9000 | FastCGI | Interne (réseau Docker) |

| MariaDB | 3306 | MySQL | Interne (réseau Docker) |# Ou utilisez FileZilla avec les mêmes identifiants

```

## 💻 Commandes de vérification

### Erreur de permissions

```bash

# Vérifier que tous les containers sont running```bash

docker ps# Vérifier les permissions des dossiers de données

sudo chown -R $USER:$USER /home/yaabdall/data

# Vérifier les volumes```

docker volume ls | grep inception

### Réinitialiser complètement le projet

# Vérifier le network

docker network ls | grep inception```bash

make fclean

# Vérifier les utilisateurs WordPressmake

docker exec wordpress wp user list --allow-root```



# Tester la connexion HTTPS## 🎯 Checklist de validation du projet

curl -k https://yaabdall.42.fr

### Partie Obligatoire

# Voir les logs d'un service spécifique- [x] NGINX avec TLS 1.2/1.3 uniquement

docker logs nginx- [x] WordPress + PHP-FPM (sans NGINX)

docker logs wordpress- [x] MariaDB (sans NGINX)

docker logs mariadb- [x] 2 volumes (WordPress + MariaDB)

```- [x] Network Docker

- [x] Restart automatique des containers

## 📚 Documentation- [x] Pas de `tail -f` ou boucles infinies

- [x] 2 utilisateurs WordPress (dont 1 admin sans "admin" dans le nom)

- [Docker Documentation](https://docs.docker.com/)- [x] Domaine login.42.fr pointant vers l'IP locale

- [Docker Compose](https://docs.docker.com/compose/)- [x] Variables d'environnement dans .env

- [WordPress CLI](https://wp-cli.org/)- [x] Secrets non présents dans les Dockerfiles

- [NGINX Documentation](https://nginx.org/en/docs/)- [x] NGINX seul point d'entrée (port 443)

- [MariaDB Documentation](https://mariadb.com/kb/en/)

### Partie Bonus

## 🎓 Concepts Clés du Projet- [x] Redis cache pour WordPress

- [x] Serveur FTP pointant vers WordPress

### Docker- [x] Site statique (HTML/CSS/JS, pas de PHP)

- **Containerisation** : Isolation des services- [x] Adminer

- **Volumes** : Persistance des données- [x] Service supplémentaire (Portainer)

- **Networks** : Communication inter-containers

- **Docker Compose** : Orchestration multi-containers## 📊 Résumé des ports



### Sécurité| Service | Port(s) | Protocole | Accès |

- **SSL/TLS** : Chiffrement HTTPS|---------|---------|-----------|-------|

- **Secrets Management** : Fichiers .env et secrets/| NGINX | 443 | HTTPS | Public |

- **Network Isolation** : Pas d'exposition directe des services| Adminer | 8080 | HTTP | Public |

| Static Site | 8081 | HTTP | Public |

### DevOps| Portainer | 9000 | HTTP | Public |

- **Infrastructure as Code** : docker-compose.yml| FTP | 21, 21000-21010 | FTP | Public |

- **Automation** : Makefile pour la gestion| MariaDB | 3306 | MySQL | Interne |

- **Configuration Management** : Variables d'environnement| WordPress | 9000 | FastCGI | Interne |

| Redis | 6379 | Redis | Interne |

## 👥 Auteurs

## 📚 Documentation

- **yaabdall** - [Profil 42](https://profile.intra.42.fr/users/yaabdall)

- [Docker Documentation](https://docs.docker.com/)

## 📝 Licence- [Docker Compose](https://docs.docker.com/compose/)

- [WordPress CLI](https://wp-cli.org/)

Ce projet fait partie du cursus de l'école 42.- [NGINX Documentation](https://nginx.org/en/docs/)

- [MariaDB Documentation](https://mariadb.com/kb/en/)

---

## 👥 Auteurs

*Projet réalisé dans le cadre du cursus de l'école 42 - Octobre 2025*

- **yaabdall** - [Profil 42](https://profile.intra.42.fr/users/yaabdall)
- **cldalmaz** - [Profil 42](https://profile.intra.42.fr/users/cldalmaz)

## 📝 Licence

Ce projet fait partie du cursus de l'école 42.

---

*Projet réalisé dans le cadre du cursus de l'école 42 - Octobre 2025*
