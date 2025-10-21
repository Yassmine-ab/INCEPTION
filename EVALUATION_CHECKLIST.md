# ✅ Checklist d'évaluation - Inception

## 🔐 Préliminaires

### Avant de commencer
- [ ] Le fichier `.env` est dans `srcs/` et non committé
- [ ] Aucun credential/API key n'est présent dans le repository Git
- [ ] Le repository Git est bien celui de l'étudiant évalué
- [ ] Tous les fichiers sont dans le dossier `srcs/`
- [ ] Un Makefile est présent à la racine

### Commande de nettoyage
```bash
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

---

## 📋 Instructions générales

### Vérifications docker-compose.yml
- [ ] ❌ PAS de `network: host` dans le fichier
- [ ] ❌ PAS de `links:` dans le fichier
- [ ] ✅ Présence de `networks` dans le fichier

### Vérifications Dockerfiles
- [ ] ❌ PAS de `tail -f` dans les ENTRYPOINT
- [ ] ❌ PAS de commandes en background (ex: `nginx & bash`)
- [ ] ❌ PAS de `bash` ou `sh` sauf pour lancer un script
- [ ] Si ENTRYPOINT est un script, vérifier qu'il ne lance rien en background

### Vérifications scripts
- [ ] ❌ PAS de `sleep infinity`
- [ ] ❌ PAS de `tail -f /dev/null`
- [ ] ❌ PAS de `tail -f /dev/random`
- [ ] ❌ PAS de boucles infinies

### Vérification Makefile et scripts
- [ ] ❌ PAS de `--link` dans les commandes Docker

### Lancement
```bash
make
```

---

## 🏗️ Partie obligatoire

### Vue d'ensemble du projet

**Questions à poser à l'étudiant :**

1. **Comment fonctionnent Docker et docker-compose ?**
   - Docker : plateforme de conteneurisation
   - Docker Compose : outil pour orchestrer plusieurs containers

2. **Différence entre image Docker avec/sans docker-compose ?**
   - Sans : `docker run` pour chaque container manuellement
   - Avec : un seul fichier YAML pour tous les services

3. **Avantages de Docker vs VMs ?**
   - Plus léger (pas de virtualisation matérielle)
   - Démarrage plus rapide
   - Moins de ressources
   - Portabilité accrue

4. **Pertinence de la structure des dossiers ?**
   - Séparation claire des services
   - Dockerfiles isolés
   - Configuration centralisée

---

### Configuration simple

#### NGINX
- [ ] Accessible uniquement par le port 443
- [ ] Certificat SSL/TLS utilisé
- [ ] Site WordPress accessible via `https://login.42.fr`
- [ ] ❌ Site NON accessible via `http://login.42.fr`
- [ ] Pas de page d'installation WordPress visible

**Commandes de test :**
```bash
# Vérifier le port
docker ps | grep nginx

# Tester HTTPS
curl -I https://yaabdall.42.fr -k

# Tester HTTP (doit échouer)
curl http://yaabdall.42.fr
```

---

### Docker Basics

#### Dockerfiles
- [ ] Un Dockerfile par service (nginx, wordpress, mariadb)
- [ ] Aucun Dockerfile n'est vide
- [ ] Tous les Dockerfiles sont écrits par l'étudiant (pas de DockerHub)
- [ ] Pas d'images toutes faites

#### Images de base
- [ ] Chaque Dockerfile commence par `FROM debian:bookworm` ou `FROM alpine:X.X.X`
- [ ] Version = avant-dernière stable (Debian Bookworm ou Alpine)

#### Noms des images
- [ ] Images Docker ont le même nom que leur service

**Commandes de vérification :**
```bash
# Vérifier les images
docker images

# Vérifier les Dockerfiles
cat srcs/requirements/nginx/Dockerfile
cat srcs/requirements/wordpress/Dockerfile
cat srcs/requirements/mariadb/Dockerfile
```

#### Build via docker-compose
- [ ] Tous les services sont buildés via `docker compose`
- [ ] Aucun crash lors du build

---

### Docker Network

- [ ] `docker-network` est utilisé dans docker-compose.yml
- [ ] Un réseau est visible avec `docker network ls`
- [ ] L'étudiant peut expliquer simplement le docker-network

**Commandes :**
```bash
docker network ls
docker network inspect <network_name>
```

---

### NGINX avec SSL/TLS

- [ ] Présence d'un Dockerfile dans `requirements/nginx/`
- [ ] Container créé : `docker compose ps`
- [ ] Connexion HTTP (port 80) impossible
- [ ] Site accessible via HTTPS : https://login.42.fr
- [ ] Page affichée = WordPress configuré (pas d'installation)
- [ ] Certificat TLS v1.2 ou v1.3 démontré
- [ ] Certificat peut être auto-signé (warning normal)

**Commandes de test :**
```bash
# Vérifier le container
docker compose ps

# Test SSL/TLS
openssl s_client -connect yaabdall.42.fr:443 -tls1_2
openssl s_client -connect yaabdall.42.fr:443 -tls1_3

# Vérifier la config NGINX
docker exec -it nginx cat /etc/nginx/nginx.conf
```

---

### WordPress avec php-fpm et volume

#### Container et Dockerfile
- [ ] Présence d'un Dockerfile dans `requirements/wordpress/`
- [ ] ❌ PAS de NGINX dans le Dockerfile WordPress
- [ ] Container créé : `docker compose ps`

#### Volume
- [ ] Volume existe : `docker volume ls`
- [ ] Chemin `/home/login/data/` dans `docker volume inspect`

**Commandes :**
```bash
docker volume ls
docker volume inspect incepgit_wordpress_data
```

#### Fonctionnalités WordPress
- [ ] Possibilité d'ajouter un commentaire avec un utilisateur WordPress
- [ ] Connexion admin possible (username sans "admin")
- [ ] Depuis le dashboard admin : modification d'une page
- [ ] La modification est visible sur le site

**Test :**
1. Ouvrir https://yaabdall.42.fr/wp-admin
2. Se connecter avec l'admin (yaabdall_wp)
3. Modifier une page
4. Vérifier la modification sur le site

---

### MariaDB et volume

#### Container et Dockerfile
- [ ] Présence d'un Dockerfile dans `requirements/mariadb/`
- [ ] ❌ PAS de NGINX dans le Dockerfile MariaDB
- [ ] Container créé : `docker compose ps`

#### Volume
- [ ] Volume existe : `docker volume ls`
- [ ] Chemin `/home/login/data/` dans `docker volume inspect`

**Commandes :**
```bash
docker volume ls
docker volume inspect incepgit_mariadb_data
```

#### Base de données
- [ ] L'étudiant sait se connecter à la DB
- [ ] La base de données n'est pas vide

**Se connecter à la DB :**
```bash
# Méthode 1 : depuis le container
docker exec -it mariadb bash
mysql -u yaabdall -p
# Entrer le mot de passe

# Méthode 2 : commande directe
docker exec -it mariadb mysql -u yaabdall -p

# Vérifier les tables
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;
```

---

### Persistance !

#### Test de redémarrage
1. [ ] Créer une modification dans WordPress (article, page, commentaire)
2. [ ] Redémarrer la VM ou faire :
   ```bash
   make down
   make up
   ```
3. [ ] Vérifier que WordPress fonctionne toujours
4. [ ] Vérifier que MariaDB fonctionne toujours
5. [ ] Vérifier que les modifications sont toujours présentes

---

## 📊 Résumé final

### Points critiques ⚠️
- ❌ Pas de `network: host`
- ❌ Pas de `links:`
- ❌ Pas de `--link`
- ❌ Pas de commandes infinies (tail -f, sleep infinity, etc.)
- ❌ Username admin WordPress sans "admin"
- ✅ TLS v1.2/1.3
- ✅ Port 443 uniquement
- ✅ Volumes persistants
- ✅ Docker network custom
- ✅ Images buildées par l'étudiant

### Notation
- Si **UN SEUL** point critique échoue → Évaluation terminée → Note : 0
- Tous les points validés → Projet réussi ✅

---

## 🎯 Notes pour l'évaluateur

### Commandes utiles pendant l'évaluation

```bash
# État des containers
docker ps -a

# Logs en temps réel
docker compose -f srcs/docker-compose.yml logs -f

# Inspecter un container
docker inspect <container_name>

# Entrer dans un container
docker exec -it <container_name> bash

# Vérifier les processus dans un container
docker top <container_name>

# Statistiques d'utilisation
docker stats

# Vérifier le contenu d'un volume
sudo ls -la /home/yaabdall/data/wordpress/
sudo ls -la /home/yaabdall/data/mariadb/
```

### Questions bonus à poser
- Pourquoi utiliser php-fpm au lieu du module Apache ?
- Comment fonctionne FastCGI ?
- Qu'est-ce qu'un reverse proxy ?
- Différence entre COPY et ADD dans Dockerfile ?
- Pourquoi les volumes sont-ils importants ?
- Comment Docker gère-t-il les réseaux entre containers ?

---

## 🚀 Après l'évaluation

Si tout est OK :
```bash
make fclean  # Nettoyage complet
```

**Bonne évaluation ! 🎓**
