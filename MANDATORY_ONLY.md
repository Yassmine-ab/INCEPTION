# Inception - Configuration Partie Obligatoire Uniquement

## ✅ Configuration Actuelle

Ce projet Inception est maintenant configuré **uniquement** pour la partie obligatoire du sujet.

### Services Implémentés (Mandatory)

1. **NGINX** (Port 443)
   - Serveur web avec TLSv1.2/TLSv1.3
   - Point d'entrée unique vers l'infrastructure
   - Reverse proxy vers WordPress

2. **WordPress** + PHP-FPM
   - CMS WordPress avec php-fpm
   - Sans serveur NGINX interne
   - 2 utilisateurs : admin (wpadmin) + éditeur (wpeditor)

3. **MariaDB**
   - Base de données MySQL
   - Base de données WordPress
   - 2 utilisateurs configurés

### Volumes

- `wordpress_data` : Fichiers du site WordPress
  - Monté sur `/home/yaabdall/data/wordpress`
- `mariadb_data` : Base de données MariaDB
  - Monté sur `/home/yaabdall/data/mariadb`

### Network

- `inception-network` : Réseau bridge Docker reliant tous les services

### Domaine

- **https://yaabdall.42.fr** : Site WordPress

---

## 📁 Structure du Projet

```
inception/
├── Makefile                    # Build et gestion du projet
├── secrets/                    # Fichiers de secrets (ignorés par git)
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                    # Variables d'environnement
    ├── docker-compose.yml      # Orchestration des services (MANDATORY ONLY)
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init-db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            └── tools/
                └── init-wordpress.sh
```

---

## 🚀 Utilisation

### Démarrer le projet
```bash
make all
```

### Arrêter les services
```bash
make down
```

### Nettoyer complètement
```bash
make fclean
```

### Reconstruire tout
```bash
make re
```

### Voir les logs
```bash
make logs
```

### Voir le statut
```bash
make status
```

---

## 🎯 Checklist Partie Obligatoire

### Services
- ✅ NGINX avec TLSv1.2/1.3 uniquement
- ✅ WordPress + php-fpm (sans NGINX)
- ✅ MariaDB (sans NGINX)

### Volumes
- ✅ Volume pour la base de données WordPress
- ✅ Volume pour les fichiers du site WordPress
- ✅ Volumes montés dans `/home/yaabdall/data/`

### Network
- ✅ Docker network reliant les containers
- ✅ Pas de `network: host`
- ✅ Pas de `--link` ou `links:`

### Configuration
- ✅ Dockerfiles personnalisés (pas d'images toutes faites)
- ✅ Image de base : Debian ou Alpine
- ✅ Pas de tag `latest`
- ✅ Restart automatique des containers
- ✅ Pas de commandes infinies (`tail -f`, `sleep infinity`, etc.)

### Sécurité
- ✅ Pas de mots de passe dans les Dockerfiles
- ✅ Variables d'environnement dans `.env`
- ✅ Secrets dans le dossier `secrets/`
- ✅ Point d'entrée unique : NGINX sur port 443

### WordPress
- ✅ 2 utilisateurs configurés
- ✅ Nom admin ne contient pas "admin" ou "administrator"
- ✅ Admin : `wpadmin`
- ✅ Utilisateur supplémentaire : `wpeditor`

### Domaine
- ✅ Domaine : `yaabdall.42.fr`
- ✅ Redirige vers l'IP locale

---

## 🔒 Variables d'Environnement (.env)

Les variables suivantes sont configurées dans `srcs/.env` :

- `DOMAIN_NAME` : yaabdall.42.fr
- `MYSQL_ROOT_PASSWORD` : Mot de passe root MariaDB
- `MYSQL_DATABASE` : wordpress
- `MYSQL_USER` : Utilisateur MySQL
- `MYSQL_PASSWORD` : Mot de passe utilisateur MySQL
- `WP_ADMIN_USER` : wpadmin (pas "admin"!)
- `WP_ADMIN_PASSWORD` : Mot de passe admin WordPress
- `WP_ADMIN_EMAIL` : Email admin
- `WP_TITLE` : Titre du site
- `WP_URL` : URL du site
- `WP_USER` : Utilisateur WordPress supplémentaire
- `WP_USER_PASSWORD` : Son mot de passe
- `WP_USER_EMAIL` : Son email

---

## 📋 Notes Importantes

### Changements Effectués

1. **Makefile nettoyé**
   - Suppression des références à Portainer, Adminer, FTP, Site statique
   - Suppression de la création du dossier `portainer_data`
   - Affichage simplifié (uniquement WordPress)

2. **docker-compose.yml créé**
   - 3 services uniquement : nginx, wordpress, mariadb
   - 2 volumes : wordpress_data, mariadb_data
   - 1 network : inception-network
   - Healthcheck sur MariaDB
   - Dependencies correctes

3. **.env vérifié**
   - Contient uniquement les variables obligatoires
   - Pas de variables bonus (FTP_USER, FTP_PASSWORD, etc.)

4. **BONUS.md archivé**
   - Renommé en `BONUS.md.bak`
   - Conservé pour référence future si besoin

---

## ✅ Prêt pour la Défense

Le projet est maintenant configuré **strictement** selon la partie obligatoire :

- ❌ Pas de Redis
- ❌ Pas de FTP
- ❌ Pas d'Adminer
- ❌ Pas de Portainer
- ❌ Pas de site statique

- ✅ Uniquement NGINX + WordPress + MariaDB
- ✅ Respect de toutes les règles du sujet
- ✅ Architecture conforme au diagramme
- ✅ Prêt pour évaluation

---

## 🛠️ Pour Restaurer les Bonus (si besoin plus tard)

Si vous souhaitez réactiver les bonus :

1. Restaurer `BONUS.md` : `mv BONUS.md.bak BONUS.md`
2. Récupérer l'ancien docker-compose.yml depuis Git
3. Restaurer l'ancien Makefile depuis Git
4. Recréer les dossiers bonus dans `srcs/requirements/`

---

**Date de conversion en mode mandatory-only : 14 octobre 2025**
