#!/bin/bash

# Script de vérification pour Inception
# Usage: ./check.sh

echo "========================================"
echo "  INCEPTION - Vérification du Projet"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if docker is running
echo -n "Docker daemon: "
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    exit 1
fi

# Check /etc/hosts configuration
echo -n "Domain configuration: "
if grep -q "yaabdall.42.fr" /etc/hosts; then
    echo -e "${GREEN}✓ yaabdall.42.fr configured${NC}"
else
    echo -e "${RED}✗ yaabdall.42.fr not found in /etc/hosts${NC}"
fi

# Check data directories
echo -n "Data directories: "
if [ -d "/home/yaabdall/data/wordpress" ] && [ -d "/home/yaabdall/data/mariadb" ]; then
    echo -e "${GREEN}✓ Exist${NC}"
else
    echo -e "${YELLOW}! Creating directories${NC}"
    mkdir -p /home/yaabdall/data/{wordpress,mariadb,portainer}
fi

echo ""
echo "========================================="
echo "  Containers Status"
echo "========================================="

containers=("nginx" "wordpress" "mariadb" "redis" "ftp" "adminer" "website" "portainer")

for container in "${containers[@]}"; do
    echo -n "$container: "
    if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
        status=$(docker inspect -f '{{.State.Status}}' $container)
        if [ "$status" = "running" ]; then
            echo -e "${GREEN}✓ Running${NC}"
        else
            echo -e "${YELLOW}! $status${NC}"
        fi
    else
        echo -e "${RED}✗ Not found${NC}"
    fi
done

echo ""
echo "========================================="
echo "  Services URLs"
echo "========================================="

urls=(
    "WordPress|https://yaabdall.42.fr"
    "WordPress Admin|https://yaabdall.42.fr/wp-admin"
    "Adminer|https://yaabdall.42.fr:8080"
    "Static Site|http://yaabdall.42.fr:8081"
    "Portainer|https://yaabdall.42.fr:9000"
)

for url_pair in "${urls[@]}"; do
    IFS='|' read -r name url <<< "$url_pair"
    printf "%-20s : %s\n" "$name" "$url"
done

echo ""
echo "========================================="
echo "  Quick Tests"
echo "========================================="

# Test NGINX
echo -n "NGINX SSL: "
if curl -k -s https://yaabdall.42.fr > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi

# Test MariaDB
echo -n "MariaDB: "
if docker exec mariadb mysqladmin ping -h localhost -uroot -proot_secure_password_123 --silent 2>/dev/null; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi

# Test Redis
echo -n "Redis: "
if docker exec redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✓ Responding${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi

# Test WordPress CLI
echo -n "WordPress: "
if docker exec wordpress wp core version --allow-root > /dev/null 2>&1; then
    version=$(docker exec wordpress wp core version --allow-root 2>/dev/null)
    echo -e "${GREEN}✓ Version $version${NC}"
else
    echo -e "${RED}✗ Not responding${NC}"
fi

echo ""
echo "========================================="
echo "  Docker Info"
echo "========================================="

echo "Networks:"
docker network ls | grep inception

echo ""
echo "Volumes:"
docker volume ls | grep inception

echo ""
echo "Images:"
docker images | grep -E "nginx|wordpress|mariadb|redis|ftp|adminer|website|portainer" | grep -v "REPOSITORY"

echo ""
echo "========================================="
echo "  Resources Usage"
echo "========================================="

docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "========================================"
echo "  Verification Complete!"
echo "========================================"
