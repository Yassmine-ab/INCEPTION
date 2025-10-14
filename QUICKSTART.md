# 🚀 Quick Start Guide - Inception (Mandatory Only)

## Installation en 5 minutes

### 1. Prérequis
```bash
# Vérifier Docker
docker --version
docker compose version  # ou docker-compose --version
```

### 2. Configuration initiale
```bash
# Configurer le domaine local
sudo nano /etc/hosts
# Ajouter: 127.0.0.1 yaabdall.42.fr

# Créer les dossiers de données
mkdir -p /home/yaabdall/data/wordpress
mkdir -p /home/yaabdall/data/mariadb
```

### 3. Personnalisation (IMPORTANT !)
```bash
# Éditer les variables d'environnement
nano srcs/.env

# Changez au minimum tous les mots de passe :
# - MYSQL_ROOT_PASSWORD
# - MYSQL_PASSWORD
# - WP_ADMIN_PASSWORD
# - WP_USER_PASSWORD
```

### 4. Lancement
```bash
# Démarrer tous les services
make

# Ou étape par étape
make all          # Build et start
make status       # Vérifier l'état
make logs         # Voir les logs
```

### 5. Vérification
```bash
# Vérifier les containers
docker ps

# Résultat attendu : 3 containers running
# - nginx
# - wordpress
# - mariadb
```

## 🌐 Accès aux Services

### Site WordPress
- **URL** : https://yaabdall.42.fr
- **Admin** : https://yaabdall.42.fr/wp-admin
  - Username: `wpadmin`
  - Password: `admin_secure_password_789`

### Login Éditeur
- Username: `wpeditor`
- Password: `editor_secure_password_012`

⚠️ **Note** : Le navigateur affichera un avertissement de sécurité car le certificat SSL est auto-signé. Cliquez sur "Avancé" → "Accepter le risque" pour continuer.

## 🛠️ Commandes Utiles

```bash
# Démarrage
make              # Build et start
make up           # Start sans rebuild

# Arrêt
make down         # Stop tous les services
make stop         # Pause les services

# Nettoyage
make clean        # Supprimer containers/networks
make fclean       # Nettoyage complet + données
make re           # Rebuild from scratch

# Monitoring
make status       # État des services
make logs         # Logs en temps réel

# Debug
docker ps -a                        # Tous les containers
docker logs nginx                   # Logs NGINX
docker logs wordpress               # Logs WordPress
docker logs mariadb                 # Logs MariaDB
docker exec -it wordpress bash      # Shell WordPress
```

## 🔧 Dépannage Rapide

### Services ne démarrent pas
```bash
# Voir les erreurs
make logs

# Rebuild complet
make fclean
make
```

### Problème de permissions
```bash
sudo chown -R $USER:$USER /home/yaabdall/data
sudo chmod -R 755 /home/yaabdall/data
```

### NGINX refuse de démarrer (port 443 occupé)
```bash
# Vérifier qui utilise le port 443
sudo lsof -i :443

# Tuer le processus si nécessaire
sudo kill -9 <PID>
```

### WordPress ne se connecte pas à MariaDB
```bash
# Vérifier que MariaDB est prêt
docker exec mariadb mysqladmin ping -h localhost -uroot -p$MYSQL_ROOT_PASSWORD

# Voir les logs MariaDB
docker logs mariadb

# Vérifier les variables d'environnement
docker exec wordpress env | grep MYSQL
```

### Certificat SSL invalide
```bash
# Normal pour un certificat auto-signé
# Dans le navigateur : Avancé → Accepter le risque
```

## 📊 Checklist Avant la Défense

- [ ] `/etc/hosts` contient `127.0.0.1 yaabdall.42.fr`
- [ ] Dossiers `/home/yaabdall/data/*` existent et ont les bonnes permissions
- [ ] `make` démarre tous les services sans erreur
- [ ] 3 containers running (`docker ps`)
- [ ] https://yaabdall.42.fr accessible
- [ ] Login WordPress admin fonctionne
- [ ] 2 utilisateurs WordPress existent
- [ ] Pas de mots de passe dans les Dockerfiles
- [ ] `.env` et `secrets/` dans `.gitignore`
- [ ] Volumes persistants après `make down` puis `make up`

## 💾 Sauvegarde

```bash
# Sauvegarder la base de données
docker exec mariadb mysqldump -uroot -p$MYSQL_ROOT_PASSWORD wordpress > backup.sql

# Sauvegarder les fichiers WordPress
tar -czf wordpress-backup.tar.gz /home/yaabdall/data/wordpress

# Restaurer la base de données
docker exec -i mariadb mysql -uroot -p$MYSQL_ROOT_PASSWORD wordpress < backup.sql
```

## 🎯 Tests de Validation

```bash
# Test 1: Tous les containers running
docker ps | grep -E "nginx|wordpress|mariadb" | wc -l
# Résultat attendu: 3

# Test 2: Network existe
docker network ls | grep inception
# Résultat: 1 ligne

# Test 3: Volumes existent
docker volume ls | grep inception
# Résultat: 2 volumes (wordpress_data, mariadb_data)

# Test 4: NGINX SSL fonctionne
curl -k -I https://yaabdall.42.fr
# Résultat: HTTP/1.1 200 OK

# Test 5: WordPress users
docker exec wordpress wp user list --allow-root
# Résultat: 2 utilisateurs (wpadmin, wpeditor)

# Test 6: MariaDB accessible
docker exec mariadb mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"
# Résultat: wordpress dans la liste

# Test 7: Volume WordPress contient des fichiers
ls -la /home/yaabdall/data/wordpress
# Résultat: Dossiers wp-admin, wp-content, wp-includes

# Test 8: Restart automatique
docker stop nginx
sleep 5
docker ps | grep nginx
# Résultat: nginx redémarré automatiquement
```

## 🏗️ Architecture Résumée

```
Internet (Port 443)
        ↓
    [NGINX] ← SSL/TLS 1.2-1.3 uniquement
        ↓ FastCGI (port 9000)
  [WordPress] ← PHP-FPM 7.4
        ↓ MySQL (port 3306)
   [MariaDB] ← Base de données

Network: inception-network (bridge)
Volumes: wordpress_data, mariadb_data
```

## 📝 Points Clés à Retenir

1. **NGINX** = Seul point d'entrée (port 443 uniquement)
2. **WordPress** = PHP-FPM sans NGINX interne
3. **MariaDB** = Pas de port exposé (réseau interne)
4. **Volumes** = Persistance dans `/home/yaabdall/data/`
5. **Network** = Bridge isolé, pas de `host` ou `link`
6. **Sécurité** = TLS 1.2/1.3, pas de mots de passe en clair
7. **Admin** = Nom sans "admin" (ici: `wpadmin`)
8. **Images** = Construites localement (pas de pull Docker Hub)

## 📚 Documentation Complète

Pour plus de détails :
- **README.md** : Documentation technique complète
- **PROJECT_SUMMARY.md** : Guide détaillé du projet
- **DEFENSE.md** : Guide de défense avec Q&A

---

**Temps estimé de setup : 5-10 minutes** ⏱️

**Prêt pour la défense !** 🎓
