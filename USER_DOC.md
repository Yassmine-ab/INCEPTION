# USER_DOC.md - User Operations Guide

## Overview

This document explains how to operate the Inception Docker infrastructure. It covers everything an end-user or system administrator needs to know to start, stop, and maintain the services.

## What is Inception?

Inception is a complete web infrastructure running in Docker containers:
- **Website** - WordPress content management system hosted securely via HTTPS
- **Database** - MariaDB server storing WordPress content and user information
- **Web Server** - NGINX reverse proxy handling HTTPS connections and routing requests

All services run in isolated containers and communicate through a private Docker network.

## Getting Started

### Prerequisites

You need:
- Linux machine with Docker installed (`docker --version`)
- Docker Compose (`docker-compose --version`)
- Root or sudo access to run Docker commands
- Internet connection for first-time setup

### Initial Access

1. **Configure domain name** - Add this to your machine's `/etc/hosts`:
   ```bash
   echo "127.0.0.1 yassabda.42.fr" | sudo tee -a /etc/hosts
   ```
   
2. **Start services** - From the project root directory:
   ```bash
   make all
   ```
   
   This will:
   - Build Docker images from Dockerfiles
   - Create volumes for WordPress and database
   - Start all containers
   - Initialize the database
   - Install WordPress
   
   **First startup takes 2-3 minutes** as WordPress downloads and initializes.

3. **Access the website**:
   ```
   https://yassabda.42.fr
   ```
   
   Your browser will warn about the self-signed certificate. Click "Accept" to proceed.

## Service Operations

### Viewing the Website

Open your web browser and visit:
```
https://yassabda.42.fr
```

The WordPress homepage displays with a welcome page or existing content depending on your WordPress configuration.

### Accessing the Admin Panel

1. Navigate to: `https://yassabda.42.fr/wp-admin/`
2. Log in with:
   - **Username:** `yass` (administrator account)
   - **Password:** `ephemere`

Alternative user account:
   - **Username:** `yassabda` (editor account)
   - **Password:** `ephemere`

### Managing Credentials

Credentials are stored in the `.env` file located in `srcs/.env`:

```bash
cat srcs/.env
```

Key variables:
- `DOMAIN_NAME` - Your website domain
- `MYSQL_ROOT_PASSWORD` - Database root password
- `MYSQL_USER` / `MYSQL_PASSWORD` - WordPress database user credentials
- `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` - WordPress admin login
- `WP_USER` / `WP_USER_PASSWORD` - Additional WordPress user login

**⚠️ Important:** Never share or commit the `.env` file to version control.

## Starting and Stopping Services

### Start All Services (Fresh Installation)
```bash
make all
```
Builds images, creates volumes, and starts containers.

### Start Previously Built Services
```bash
make up
```
Starts containers that were already built (faster than `make all`).

### Stop Services (Graceful Shutdown)
```bash
make down
```
Stops all containers and removes the network. **Volumes persist** - data is not lost.

### Pause Services (Without Stopping)
```bash
make stop
```
Pauses all containers. They still exist but are not consuming CPU/memory.

### Resume Paused Services
```bash
make start
```
Resumes previously paused containers.

## Checking Service Status

### View Service Status
```bash
make status
```

Output shows:
```
NAME                COMMAND                 SERVICE    STATUS       PORTS
nginx               "nginx -g 'daemon off;" nginx      Up 2 minutes 0.0.0.0:443->443/tcp
wordpress           "/usr/local/bin/init-wp" wordpress Up 2 minutes 9000/tcp
mariadb             "/usr/local/bin/init-db"mariadb    Up 3 minutes 3306/tcp
```

**Status meanings:**
- `Up X minutes` - Container is running normally
- `Exited` - Container stopped (check logs for errors)
- `Restarting` - Container crashed and is automatically restarting

### View Live Logs
```bash
make logs
```

Shows real-time output from all services. Press `Ctrl+C` to exit.

Individual service logs:
```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### Specific Recent Logs
```bash
docker compose -f srcs/docker-compose.yml logs --tail=100 mariadb
```
Shows last 100 lines from MariaDB.

## Data Persistence

All data is stored in volumes on your host machine:

### WordPress Files Location
```bash
ls -la /home/yaabdall/data/wordpress/
```

Contains:
- WordPress core files (`wp-admin`, `wp-content`, `wp-includes`, `index.php`, etc.)
- Theme files
- Plugin files
- Uploaded media

### Database Files Location
```bash
ls -la /home/yaabdall/data/mariadb/
```

Contains:
- Database files for WordPress
- MariaDB system databases
- User data

### Data Persistence Behavior

| Scenario | WordPress Data | Database Data |
|----------|---|---|
| `make down` (stop services) | ✅ Persists | ✅ Persists |
| `make stop` + `make start` | ✅ Persists | ✅ Persists |
| `make clean` (clean containers) | ✅ Persists | ✅ Persists |
| `make fclean` (full cleanup) | ❌ Deleted | ❌ Deleted |
| Container crash + auto-restart | ✅ Persists | ✅ Persists |

## Health Checks

### All Services Running?
```bash
make status
```

All containers should show `Up X minutes`.

### Database Responding?
```bash
docker compose -f srcs/docker-compose.yml exec mariadb mysql -uroot -p -e "SELECT 1;" 2>/dev/null | grep -q "1" && echo "✅ Database OK" || echo "❌ Database ERROR"
```

Type the MYSQL_ROOT_PASSWORD when prompted (from `.env` file).

### WordPress Running?
```bash
docker compose -f srcs/docker-compose.yml exec wordpress curl -s http://localhost:9000 2>/dev/null | head -20
```

Should show PHP output (not HTML - WordPress talks to nginx via FastCGI).

### NGINX Responding?
```bash
curl -k https://yassabda.42.fr/ 2>/dev/null | head -20
```

Should return WordPress HTML content (ignore SSL certificate warnings with `-k`).

### Complete System Check Script
```bash
echo "=== SERVICE STATUS ===" && \
docker compose -f srcs/docker-compose.yml ps && \
echo "" && \
echo "=== VOLUME CHECK ===" && \
df -h /home/yaabdall/data/wordpress /home/yaabdall/data/mariadb && \
echo "" && \
echo "=== NETWORK CHECK ===" && \
docker network inspect inception-network | grep -A 3 "Containers"
```

## Common Operations

### Reset Everything to Fresh Install
```bash
make fclean   # Remove containers, networks, volumes, data
make all      # Fresh build and install
```

Useful if you want a completely clean slate. **Warning:** This deletes all data.

### Just Rebuild Images (Keep Data)
```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

Rebuilds Docker images from Dockerfiles without removing volumes.

### Access Database Directly
```bash
docker compose -f srcs/docker-compose.yml exec mariadb mysql -u yassabda -p
```

Password: `ephemere` (from `.env`)

Then you can run SQL commands:
```sql
USE wordpress;
SELECT user_login, user_email FROM wp_users;
EXIT;
```

### Create WordPress Backup
```bash
# Backup WordPress files
tar -czf wordpress_backup_$(date +%Y%m%d).tar.gz /home/yaabdall/data/wordpress/

# Backup database
docker compose -f srcs/docker-compose.yml exec mariadb mysqldump -u yassabda -p wordpress > wordpress_db_backup_$(date +%Y%m%d).sql
```

## Troubleshooting

### Services Won't Start
```bash
# Check what went wrong
make logs

# Verify Docker is running
docker ps

# Check available disk space
df -h /home/yaabdall/data
```

### Can't Access Website
```bash
# Verify domain is configured
ping yassabda.42.fr

# Check if NGINX is running
docker compose -f srcs/docker-compose.yml logs nginx | tail -20

# Test NGINX directly
curl -k https://127.0.0.1
```

### WordPress Shows Database Error
```bash
# Check MariaDB logs
docker compose -f srcs/docker-compose.yml logs mariadb

# Verify database exists
docker compose -f srcs/docker-compose.yml exec mariadb mysql -uroot -p -e "SHOW DATABASES;" 

# Check WordPress can reach database
docker compose -f srcs/docker-compose.yml exec wordpress mysql -h mariadb -u yassabda -p -e "SELECT 1;" 
```

### White Page or 500 Error
```bash
# Check WordPress logs
docker compose -f srcs/docker-compose.yml exec wordpress tail -20 /var/log/php-fpm.log

# Check NGINX logs  
docker compose -f srcs/docker-compose.yml logs nginx
```

### SSL Certificate Warnings
This is normal with self-signed certificates. Options:
1. Click "Advanced" → "Proceed to site" in your browser
2. Add the site to your browser's trusted sites
3. Use `curl -k` to ignore SSL warnings from command line

### Database Storage Growing Too Large
```bash
# Check disk usage
du -sh /home/yaabdall/data/mariadb

# Clean up database
docker compose -f srcs/docker-compose.yml exec mariadb mysql -u yassabda -p -e "OPTIMIZE TABLE wordpress.wp_posts; OPTIMIZE TABLE wordpress.wp_postmeta;"
```

## Emergency Recovery

### All Data Lost but Services Still Running
```bash
# Stop services
make down

# Verify data is gone
ls /home/yaabdall/data/wordpress
ls /home/yaabdall/data/mariadb

# Restore from backup (if you have one)
tar -xzf wordpress_backup_20260718.tar.gz -C /

# Restart services
make up
```

### Container Keeps Crashing
```bash
# Check logs for error
docker compose -f srcs/docker-compose.yml logs <service-name>

# Full system reset
make fclean
make all
```

### Need to Update Passwords
1. Edit `srcs/.env` file
2. Run `make fclean` (removes old data)
3. Run `make all` (creates new installation with new passwords)

**Note:** Changing passwords of existing accounts requires SQL commands.

## Support & Resources

- **Project Documentation:** See [README.md](README.md)
- **Developer Setup:** See [DEV_DOC.md](DEV_DOC.md)
- **Docker Documentation:** https://docs.docker.com
- **WordPress Help:** https://wordpress.org/support
- **MariaDB Help:** https://mariadb.com/kb

---

**Last Updated:** 2026-07-18  
**For:** End Users and System Administrators
