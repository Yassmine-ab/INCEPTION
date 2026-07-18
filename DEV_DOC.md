# DEV_DOC.md - Developer Documentation

## Overview

This document provides comprehensive information for developers who need to set up, build, deploy, modify, and debug the Inception Docker infrastructure.

## Environment Setup

### System Requirements

**Minimum specifications:**
- 4 GB RAM
- 10 GB free disk space
- Linux kernel 4.1+ (for Docker overlay2 storage driver)
- Docker Engine 20.10+
- Docker Compose 2.0+

**Recommended:**
- 8 GB RAM
- 20 GB free disk space
- Docker Engine 24.0+ (latest stable)
- Docker Compose 2.20+

### Installing Prerequisites

#### On Debian/Ubuntu:
```bash
# Update package list
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io

# Install Docker Compose
sudo apt-get install -y docker-compose

# Add current user to docker group (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose --version
```

#### On Alpine/Minimal Linux:
```bash
apk add --no-cache docker docker-compose
```

### Project Cloning

```bash
# Clone repository
git clone <repository-url> incep
cd incep

# Check directory structure
ls -la
tree -L 3 srcs/
```

## Configuration

### Environment Variables

All configuration uses `srcs/.env` file:

```bash
cat srcs/.env
```

**Key variables:**

| Variable | Purpose | Default |
|----------|---------|---------|
| `DOMAIN_NAME` | Website domain | `yassabda.42.fr` |
| `MYSQL_ROOT_PASSWORD` | Database root password | `ephemere` |
| `MYSQL_DATABASE` | WordPress database name | `wordpress` |
| `MYSQL_USER` | WordPress DB user | `yassabda` |
| `MYSQL_PASSWORD` | WordPress DB password | `ephemere` |
| `WP_URL` | WordPress site URL | `https://yassabda.42.fr` |
| `WP_ADMIN_USER` | Admin username | `yass` |
| `WP_ADMIN_PASSWORD` | Admin password | `ephemere` |

### Domain Configuration

For local testing, add to `/etc/hosts`:
```bash
echo "127.0.0.1 yassabda.42.fr" | sudo tee -a /etc/hosts
```

Verify:
```bash
ping yassabda.42.fr  # Should resolve to 127.0.0.1
```

## Building and Deployment

### Build Process

```bash
# Complete build (downloads images, builds containers, starts services)
make all
```

This Makefile target:
1. Creates data directories (`/home/yaabdall/data/wordpress` and `/mariadb`)
2. Runs `docker compose build` (builds images from Dockerfiles)
3. Runs `docker compose up -d` (starts containers in background)
4. Displays startup confirmation

### Build Steps Breakdown

#### Manual Build:
```bash
# Navigate to project
cd ~/42/incep

# Build images
docker compose -f srcs/docker-compose.yml build

# Start containers
docker compose -f srcs/docker-compose.yml up -d

# Verify containers
docker compose -f srcs/docker-compose.yml ps
```

#### With Rebuild (Force):
```bash
# Rebuild without using cache
docker compose -f srcs/docker-compose.yml build --no-cache

# Or start fresh
docker compose -f srcs/docker-compose.yml up -d --build --force-recreate
```

### Deployment Architecture

#### Image Build Flow:
```
srcs/requirements/
├── nginx/Dockerfile → mariadb image
├── wordpress/Dockerfile → wordpress image
└── mariadb/Dockerfile → nginx image

Each Dockerfile:
1. Pulls base image (Debian bookworm)
2. Installs dependencies
3. Copies configuration files
4. Copies initialization scripts
5. Sets entrypoint
```

#### Container Startup Flow:
```
docker compose up -d
    ↓
1. Create network: inception-network
2. Create volumes: wordpress_data, mariadb_data
3. Start mariadb container
    ├─ Run init-db.sh
    ├─ Initialize MySQL files
    ├─ Create database & user
    └─ Wait for ready signal
4. Start wordpress container
    ├─ Wait for mariadb healthy
    ├─ Download WordPress core
    ├─ Create wp-config.php
    ├─ Install WordPress
    └─ Start PHP-FPM
5. Start nginx container
    ├─ Generate SSL certificate
    ├─ Start NGINX daemon
    └─ Listen on port 443
6. All containers apply restart: unless-stopped
```

## Volume Configuration

### Persistent Storage

**WordPress Volume:**
```yaml
wordpress_data:
  driver: local
  driver_opts:
    type: none
    o: bind
    device: /home/yaabdall/data/wordpress
```

**Database Volume:**
```yaml
mariadb_data:
  driver: local
  driver_opts:
    type: none
    o: bind
    device: /home/yaabdall/data/mariadb
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume details
docker volume inspect incep_wordpress_data

# Manual mount point check
mount | grep /home/yaabdall/data

# Volume space usage
du -sh /home/yaabdall/data/wordpress /home/yaabdall/data/mariadb

# Backup volume
tar -czf wordpress_backup.tar.gz /home/yaabdall/data/wordpress

# Delete volume (WARNING: deletes data)
docker volume rm incep_wordpress_data
```

## Network Configuration

### Network Topology

```
inception-network (bridge network)
├── nginx (exposed: 0.0.0.0:443→443/tcp)
├── wordpress (internal: wordpress:9000)
└── mariadb (internal: mariadb:3306)
```

### Network Commands

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception-network

# Test container connectivity
docker compose -f srcs/docker-compose.yml exec wordpress ping mariadb
docker compose -f srcs/docker-compose.yml exec wordpress ping nginx

# DNS verification (containers discover each other)
docker compose -f srcs/docker-compose.yml exec wordpress nslookup mariadb
```

### DNS Resolution

Containers communicate via hostnames:
```bash
# WordPress connects to MariaDB
mysql -h mariadb -u yassabda -p wordpress

# NGINX proxies to PHP-FPM
fastcgi_pass wordpress:9000;
```

## Container Management

### Essential Commands

```bash
# View all containers
docker ps -a

# Logs for specific service
docker compose -f srcs/docker-compose.yml logs wordpress

# Real-time logs
docker compose -f srcs/docker-compose.yml logs -f mariadb

# Execute command inside container
docker compose -f srcs/docker-compose.yml exec wordpress bash

# Stop individual container
docker stop incep-wordpress-1

# Restart container
docker restart incep-mariadb-1

# Remove stopped containers
docker container prune

# Inspect container
docker inspect incep-nginx-1
```

### Container Lifecycle

```bash
# Start (from existing state)
make start
# or
docker compose -f srcs/docker-compose.yml start

# Pause (freeze containers)
make stop
# or
docker compose -f srcs/docker-compose.yml stop

# Resume
make restart
# or
docker compose -f srcs/docker-compose.yml start

# Remove (stop and delete)
make down
# or
docker compose -f srcs/docker-compose.yml down

# Remove everything including volumes
make fclean
# or
docker compose -f srcs/docker-compose.yml down -v
sudo rm -rf /home/yaabdall/data
```

## Debugging

### Accessing Container Shells

```bash
# NGINX container
docker compose -f srcs/docker-compose.yml exec nginx sh

# WordPress/PHP container
docker compose -f srcs/docker-compose.yml exec wordpress bash

# MariaDB container
docker compose -f srcs/docker-compose.yml exec mariadb bash
```

### Checking Service Status

```bash
# Full status
docker compose -f srcs/docker-compose.yml ps

# Check if services restart properly
docker compose -f srcs/docker-compose.yml config | grep -A 2 "restart"

# Monitor restart attempts
watch 'docker compose -f srcs/docker-compose.yml ps'  # Updates every 2 seconds
```

### Log Analysis

```bash
# Nginx error log
docker compose -f srcs/docker-compose.yml exec nginx cat /var/log/nginx/error.log

# PHP-FPM error log
docker compose -f srcs/docker-compose.yml exec wordpress tail -50 /var/log/php8.2-fpm.log

# MariaDB error log
docker compose -f srcs/docker-compose.yml exec mariadb tail -50 /var/log/mysql/error.log

# WordPress debug log (if enabled)
docker compose -f srcs/docker-compose.yml exec wordpress cat /var/www/html/wp-content/debug.log
```

### Database Inspection

```bash
# Connect to database
docker compose -f srcs/docker-compose.yml exec mariadb mysql -u yassabda -p wordpress

# Within MySQL shell
SHOW DATABASES;
SHOW TABLES;
SELECT * FROM wp_users;
SELECT option_name, option_value FROM wp_options LIMIT 10;
```

### File System Inspection

```bash
# List WordPress files
docker compose -f srcs/docker-compose.yml exec wordpress ls -la /var/www/html

# Check file permissions
docker compose -f srcs/docker-compose.yml exec wordpress ls -l /var/www/html/wp-config.php

# Find large files
docker compose -f srcs/docker-compose.yml exec wordpress du -sh /var/www/html/*
```

## Dockerfile Structure

### NGINX Dockerfile Breakdown

```dockerfile
FROM debian:bookworm
# Base image: Debian bookworm (latest stable)

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*
# Install nginx and openssl, clean apt cache to reduce layer size

RUN mkdir -p /etc/nginx/ssl
# Create SSL certificate directory

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/yaabdall.key \
    -out /etc/nginx/ssl/yaabdall.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=yaabdall.42.fr"
# Generate self-signed certificate

COPY conf/nginx.conf /etc/nginx/nginx.conf
# Copy custom nginx configuration

EXPOSE 443
# Document port (doesn't publish, just metadata)

ENTRYPOINT ["nginx", "-g", "daemon off;"]
# Run nginx in foreground (required for Docker)
```

### WordPress Dockerfile Breakdown

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*
# Install PHP-FPM, MySQL extension, curl for wp-cli, mysql CLI

RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 0.0.0.0:9000/g' \
    /etc/php/8.2/fpm/pool.d/www.conf
# Configure PHP-FPM to listen on TCP port instead of Unix socket
# Allows nginx container to connect via network

RUN mkdir -p /var/www/html
WORKDIR /var/www/html
# Create and set WordPress directory

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp
# Download wp-cli tool for WordPress management

COPY tools/init-wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-wordpress.sh
# Copy and make initialization script executable

EXPOSE 9000
# Expose PHP-FPM port to nginx container

ENTRYPOINT ["/usr/local/bin/init-wordpress.sh"]
# Run initialization on startup
```

### MariaDB Dockerfile Breakdown

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*
# Install MariaDB server only

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
# Copy custom MariaDB configuration

COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh
# Copy initialization script

EXPOSE 3306
# Expose port to other containers

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
# Run initialization on startup
```

## Initialization Scripts

### init-db.sh (MariaDB)

**Purpose:** Initialize database, create users, and start MariaDB

**Flow:**
1. Create MySQL runtime directory
2. Check if database already initialized (`.initialized` flag)
3. If new: run `mysql_install_db` to initialize filesystem
4. Start MariaDB temporarily without networking
5. Wait up to 30 seconds for MariaDB to be ready
6. Create database and user via SQL commands
7. Shut down temporary MariaDB process
8. Start MariaDB in foreground with `exec` (replaces PID 1)

**Key behaviors:**
- Idempotent: only initializes on first run
- Uses environment variables for passwords
- Proper signal handling with `exec`

### init-wordpress.sh (WordPress)

**Purpose:** Wait for database, download WordPress, create config, install

**Flow:**
1. Wait for MariaDB to be ready (ping loop)
2. Check if WordPress already installed
3. If new:
   - Download WordPress core with `wp core download`
   - Generate `wp-config.php` with database settings
   - Run WordPress installation (create tables, admin user)
   - Create additional user account
4. Fix file permissions (www-data:www-data)
5. Start PHP-FPM in foreground with `exec`

**Key behaviors:**
- Waits for database dependency to be ready
- Only installs on first run
- Uses `wp-cli` for programmatic installation
- Proper permissions for web server

### init-nginx.sh (Optional - can be added)

**Purpose:** Generate SSL certificate, validate configuration, start NGINX

**Benefits of adding:**
- Dynamic certificate generation using `$DOMAIN_NAME`
- Configuration validation before start
- Proper error handling

## Modifying Project

### Changing Domain Name

1. Update `srcs/.env`:
   ```bash
   DOMAIN_NAME=mynewdomain.42.fr
   WP_URL=https://mynewdomain.42.fr
   ```

2. Update `/etc/hosts`:
   ```bash
   echo "127.0.0.1 mynewdomain.42.fr" | sudo tee -a /etc/hosts
   ```

3. Update NGINX certificate (create `init-nginx.sh`) to use `$DOMAIN_NAME`

4. Rebuild:
   ```bash
   docker compose -f srcs/docker-compose.yml down
   docker compose -f srcs/docker-compose.yml up -d --build
   ```

### Changing WordPress Version

**Default:** Latest stable via `wp core download`

To pin specific version, edit `init-wordpress.sh`:
```bash
wp core download --version=6.4 --allow-root
```

### Adding PHP Extensions

Edit WordPress Dockerfile and rebuild:
```dockerfile
RUN apt-get install -y \
    php-fpm \
    php-mysql \
    php-gd \
    php-curl \
    php-xml \
    ...
```

### Increasing Database Resources

Edit `srcs/requirements/mariadb/conf/50-server.cnf`:
```ini
[mysqld]
max_connections=1000
innodb_buffer_pool_size=512M
```

## Testing Checklist

```bash
# Services running?
docker compose -f srcs/docker-compose.yml ps

# Network connectivity?
docker compose -f srcs/docker-compose.yml exec wordpress ping mariadb

# Database accessible?
docker compose -f srcs/docker-compose.yml exec wordpress mysql -h mariadb -u yassabda -p wordpress -e "SELECT 1;"

# WordPress installed?
curl -k https://yassabda.42.fr/ | grep -q "WordPress" && echo "✅ WordPress OK"

# Admin login works?
# Manual check: https://yassabda.42.fr/wp-admin

# Volumes persistent?
touch /home/yaabdall/data/wordpress/test_file.txt
make down
make up
ls /home/yaabdall/data/wordpress/test_file.txt  # Should still exist

# Auto-restart works?
docker stop incep-nginx-1
sleep 3
docker ps | grep nginx  # Should be running again
```

## Performance Optimization

### Image Size Reduction
```dockerfile
# ❌ Bad: Large layer
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# ✅ Good: Single layer
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*
```

### Build Caching
```bash
# Leverage layer caching for faster builds
docker compose -f srcs/docker-compose.yml build

# Use --no-cache to rebuild from scratch
docker compose -f srcs/docker-compose.yml build --no-cache
```

### Resource Limits
Edit `docker-compose.yml` to limit resources:
```yaml
services:
  nginx:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
```

## Cleanup

### Remove Unused Resources

```bash
# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -f

# Remove unused volumes
docker volume prune -f

# Total cleanup (keep data)
make clean

# Full cleanup (removes everything including data)
make fclean
```

## Troubleshooting Development

### Build Fails
```bash
# Check error
docker compose -f srcs/docker-compose.yml build --no-cache

# Common issue: network issues
# Use --build-arg HTTP_PROXY if behind proxy
```

### Container Exits Immediately
```bash
# Check exit code
docker compose -f srcs/docker-compose.yml ps

# View error logs
docker compose -f srcs/docker-compose.yml logs -f mariadb

# Common cause: entrypoint script errors
docker compose -f srcs/docker-compose.yml exec mariadb cat /usr/local/bin/init-db.sh
```

### Permission Denied Errors
```bash
# Run without sudo if added to docker group
newgrp docker

# Or use sudo
sudo docker ps
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Spec](https://github.com/compose-spec/compose-spec)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [MariaDB Configuration Reference](https://mariadb.com/kb/en/library/server-system-variables/)
- [WordPress Installation Guide](https://wordpress.org/support/article/how-to-install-wordpress/)

---

**Last Updated:** 2026-07-18  
**For:** Developers and DevOps Engineers
