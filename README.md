# Inception - Docker Infrastructure

*This activity has been created as part of the 42 curriculum by yaabdall.*

## Description

Inception is a system administration exercise that focuses on Docker containerization and infrastructure management. The project involves setting up a complete web server infrastructure with multiple services, demonstrating containerization best practices, networking, persistence, and security principles.

### Project Goal

Build a multi-container Docker infrastructure featuring:
- **NGINX** - Reverse proxy with TLS/SSL
- **WordPress + PHP-FPM** - Content management system
- **MariaDB** - Relational database server

All services communicate through a custom Docker network, with persistent data stored in volumes mounted on the host machine.

## Architecture

```
┌─────────────────────────────────────────────────┐
│         User Machine (Host)                     │
│  /home/yaabdall/data/                           │
│  ├── wordpress/ (volume)                        │
│  └── mariadb/ (volume)                          │
└──────────────┬──────────────────────────────────┘
               │ inception-network (bridge)
       ┌───────┼───────┬───────┐
       │       │       │       │
    ┌──▼──┐ ┌─▼───┐ ┌─▼────┐ │
    │NGINX│ │ WP  │ │Maria │ │
    │:443 │ │:9000│ │:3306 │ │
    └─────┘ └─────┘ └──────┘ │
       │       │       │      │
       └───────┴───────┴──────┘
       All containers use restart: unless-stopped
```

## Instructions

### Prerequisites

- Linux virtual machine with Docker and Docker Compose installed
- Access to root or sudo privileges
- Domain configuration (local /etc/hosts file)

### Initial Setup

```bash
# Clone the repository
git clone <repo_url>
cd incep

# Configure domain name (Linux host)
echo "127.0.0.1 yassabda.42.fr" | sudo tee -a /etc/hosts

# Build and start all services
make all

# Visit the site
https://yassabda.42.fr
```

### Available Commands

```bash
make all          # Build and start all services
make up           # Start services (already built)
make down         # Stop all services
make stop         # Pause services
make start        # Resume services
make clean        # Clean containers and networks
make fclean       # Full cleanup (including volumes)
make re           # Rebuild everything from scratch
make status       # Show service status
make logs         # View live logs
make help         # Display help message
```

### First-Time Setup Steps

1. **Build images** - `make all` automatically builds Docker images from Dockerfiles
2. **Initialize MariaDB** - Database is automatically created with configured user
3. **Install WordPress** - WordPress files and database configuration created automatically
4. **Access the site** - Navigate to `https://yassabda.42.fr` (accept self-signed certificate)

## Project Structure

```
incep/
├── Makefile                          # Build and service management
├── README.md                         # This file
├── USER_DOC.md                       # User operations guide
├── DEV_DOC.md                        # Developer documentation
├── srcs/
│   ├── .env                          # Environment variables
│   ├── docker-compose.yml            # Service configuration
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── conf/
│       │   │   └── nginx.conf       # Nginx server config
│       │   └── tools/
│       │       └── init-nginx.sh    # SSL cert generation
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   └── tools/
│       │       └── init-wordpress.sh # WordPress initialization
│       └── mariadb/
│           ├── Dockerfile
│           ├── conf/
│           │   └── 50-server.cnf    # MySQL server config
│           └── tools/
│               └── init-db.sh       # Database initialization
└── secrets/                          # Credential files (if using Docker secrets)
    ├── db_password.txt
    ├── db_root_password.txt
    └── credentials.txt
```

## Key Design Choices

### Virtual Machines vs Docker

**Docker Advantages Used:**
- **Lightweight isolation** - Containers share host OS kernel, faster than VMs
- **Portability** - Images run identically across different hosts
- **Resource efficiency** - Lower overhead than full VMs
- **Development-to-production parity** - Containerize once, deploy anywhere

### Secrets vs Environment Variables

**Implementation:**
- **Environment variables (.env file)** - Used for non-sensitive configuration (domain, database name, URLs)
- **Docker Secrets** - Recommended for sensitive data (passwords, API keys) in production
- **No hardcoded credentials** - All sensitive values read from environment or secrets

**Best practice demonstrated:**
```env
# Non-sensitive
DOMAIN_NAME=yassabda.42.fr
WP_TITLE=Inception Website

# Sensitive (would use Docker secrets in production)
MYSQL_ROOT_PASSWORD=<from .env>
```

### Docker Network vs Host Network

**Choice: Docker Network (Bridge)**
- ✅ **Isolation** - Services cannot accidentally expose to host ports
- ✅ **Container DNS** - Services communicate by container name (e.g., `mariadb:3306`)
- ✅ **Security** - Only exposed port is nginx 443 to host
- ❌ Slightly more overhead than host network
- ❌ Not used: host network would break isolation, violate requirements

**Network configuration:**
```yaml
networks:
  inception-network:
    driver: bridge
```

### Docker Volumes vs Bind Mounts

**Volumes Used:**
```yaml
wordpress_data:
  driver: local
  driver_opts:
    type: none
    o: bind
    device: /home/yaabdall/data/wordpress
```

**Why volumes instead of pure bind mounts:**
- ✅ Consistent interface (Docker manages mount details)
- ✅ Better error handling and validation
- ✅ Works across different storage backends
- ✅ Supports host-level backups and management
- ✅ Persists even when containers are removed

## Security Considerations

### TLS/SSL
- **Self-signed certificates** - Generated on first run
- **TLSv1.2 and TLSv1.3** - Only modern protocols, no deprecated versions
- **Certificate validity** - 365 days, renewed on container rebuild

### Credentials
- **No hardcoded passwords** - All values in `.env`
- **`.env` in .gitignore** - Prevents accidental credential leaks
- **Docker secrets ready** - Architecture supports Docker secrets migration

### Container Isolation
- **Custom network** - Containers isolated from external access except nginx
- **Read-only filesystem** (where possible)
- **No privilege escalation** - Containers run as service users (mysql, www-data)
- **No infinite loops** - Proper daemon configuration

## Troubleshooting

### Services won't start
```bash
# Check logs
make logs

# Verify network
docker network ls
docker inspect inception-network

# Restart everything
make fclean
make all
```

### Database connection error
```bash
# Check if MariaDB is ready
docker compose -f srcs/docker-compose.yml exec mariadb mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1"

# View MariaDB logs
docker compose -f srcs/docker-compose.yml logs mariadb
```

### WordPress installation stuck
```bash
# Check WordPress container
docker compose -f srcs/docker-compose.yml logs wordpress

# Manual WordPress setup (if needed)
docker compose -f srcs/docker-compose.yml exec wordpress wp core install --url=https://yassabda.42.fr --title="Inception Website" --admin_user=yass --admin_password=ephemere --admin_email=yass@student.42.fr --allow-root --skip-email
```

### HTTPS certificate warnings
- This is expected with self-signed certificates
- Accept the security exception in your browser
- Production would use Let's Encrypt certificates

## Resources

### Docker Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

### Networking & Security
- [Docker Networking Guide](https://docs.docker.com/network/)
- [SSL/TLS Configuration](https://wiki.debian.org/Self-signed_certificate)
- [PID 1 and Container Signals](https://hynek.me/articles/docker-signals/)

### Services
- [NGINX Server Configuration](https://nginx.org/en/docs/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB Server Documentation](https://mariadb.com/kb/en/mariadb-server/)
- [WordPress Installation Guide](https://wordpress.org/support/article/how-to-install-wordpress/)

### 42 Resources
- [42 Inception Subject](https://github.com/42School/inception)
- [42 Docker Resources](https://42.fr)

## AI Assistance Used

This project utilized AI for the following tasks:

### ✅ Areas with AI Support
- **Dockerfile optimization** - Base image selection, layer optimization, security best practices
- **docker-compose.yml structure** - YAML syntax, service configuration patterns, networking setup
- **Bash scripting** - Database initialization logic, error handling, health checks
- **Documentation** - Structure and content for README, USER_DOC, DEV_DOC files
- **NGINX configuration** - FastCGI setup with PHP-FPM, SSL configuration, server blocks

### 🔍 Manual Implementation & Verification
- **Cryptographic certificate generation** - Custom implementation for domain-specific SSL certs
- **Initialization logic** - Hand-tuned database startup sequences and health verification
- **Networking architecture** - Custom bridge network design and inter-service communication
- **Volume persistence** - Bind mount configuration for host data storage
- **All deployments, testing, and validation** - Fully manual verification of functionality

### ⚠️ Critical Review Performed
- All generated code reviewed for security implications
- Credentials management audit
- Network isolation verification
- Service startup sequence validation

---

**For user documentation:** See [USER_DOC.md](USER_DOC.md)  
**For developer setup:** See [DEV_DOC.md](DEV_DOC.md)

**Version:** 1.1  
**Last Updated:** 2026-07-18
