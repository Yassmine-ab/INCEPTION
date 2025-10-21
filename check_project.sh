#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symboles
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         INCEPTION - Vérification pré-évaluation            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Compteurs
ERRORS=0
WARNINGS=0
SUCCESS=0

# Fonction de vérification
check() {
    if [ $1 -eq 0 ]; then
        echo -e "${CHECK} $2"
        ((SUCCESS++))
    else
        echo -e "${CROSS} $2"
        ((ERRORS++))
    fi
}

check_warning() {
    if [ $1 -eq 0 ]; then
        echo -e "${CHECK} $2"
        ((SUCCESS++))
    else
        echo -e "${WARN} $2"
        ((WARNINGS++))
    fi
}

echo -e "${BLUE}[1/8] Vérification de la structure des fichiers...${NC}"
check $([ -f "Makefile" ] && echo 0 || echo 1) "Makefile présent à la racine"
check $([ -f "srcs/docker-compose.yml" ] && echo 0 || echo 1) "docker-compose.yml dans srcs/"
check $([ -f "srcs/template.env" ] && echo 0 || echo 1) "template.env présent"
check $([ -f ".gitignore" ] && echo 0 || echo 1) ".gitignore présent"
check $([ -f "srcs/requirements/nginx/Dockerfile" ] && echo 0 || echo 1) "Dockerfile NGINX"
check $([ -f "srcs/requirements/wordpress/Dockerfile" ] && echo 0 || echo 1) "Dockerfile WordPress"
check $([ -f "srcs/requirements/mariadb/Dockerfile" ] && echo 0 || echo 1) "Dockerfile MariaDB"

echo -e "\n${BLUE}[2/8] Vérification de la sécurité...${NC}"
if [ -f "srcs/.env" ]; then
    echo -e "${WARN} Fichier .env existe (normal si déjà créé)"
    if git ls-files --error-unmatch srcs/.env 2>/dev/null; then
        echo -e "${CROSS} ERREUR CRITIQUE: .env est tracké par Git !"
        ((ERRORS++))
    else
        echo -e "${CHECK} .env n'est pas tracké par Git"
        ((SUCCESS++))
    fi
else
    echo -e "${WARN} Fichier .env n'existe pas (à créer pendant l'évaluation)"
    ((WARNINGS++))
fi

# Vérifier qu'il n'y a pas de mots de passe hardcodés
if git grep -E "password.*=.*['\"].*['\"]|passwd.*=.*['\"].*['\"]" -- '*.yml' '*.sh' | grep -v "MYSQL_PASSWORD\|WP_.*PASSWORD\|\$" > /dev/null; then
    echo -e "${CROSS} Mots de passe potentiellement hardcodés trouvés"
    ((ERRORS++))
else
    echo -e "${CHECK} Pas de mots de passe hardcodés"
    ((SUCCESS++))
fi

echo -e "\n${BLUE}[3/8] Vérification docker-compose.yml...${NC}"
if grep -q "network.*:.*host" srcs/docker-compose.yml; then
    echo -e "${CROSS} CRITIQUE: 'network: host' trouvé dans docker-compose.yml"
    ((ERRORS++))
else
    echo -e "${CHECK} Pas de 'network: host'"
    ((SUCCESS++))
fi

if grep -q "links:" srcs/docker-compose.yml; then
    echo -e "${CROSS} CRITIQUE: 'links:' trouvé dans docker-compose.yml"
    ((ERRORS++))
else
    echo -e "${CHECK} Pas de 'links:'"
    ((SUCCESS++))
fi

if grep -q "networks:" srcs/docker-compose.yml; then
    echo -e "${CHECK} 'networks' présent dans docker-compose.yml"
    ((SUCCESS++))
else
    echo -e "${CROSS} 'networks' manquant dans docker-compose.yml"
    ((ERRORS++))
fi

echo -e "\n${BLUE}[4/8] Vérification des Dockerfiles...${NC}"
for dockerfile in srcs/requirements/*/Dockerfile; do
    if grep -q "tail -f\|tail -f /dev/null\|tail -f /dev/random" "$dockerfile"; then
        echo -e "${CROSS} CRITIQUE: 'tail -f' trouvé dans $dockerfile"
        ((ERRORS++))
    fi
    
    if grep -q "sleep infinity" "$dockerfile"; then
        echo -e "${CROSS} CRITIQUE: 'sleep infinity' trouvé dans $dockerfile"
        ((ERRORS++))
    fi
    
    if grep -q "FROM.*:latest" "$dockerfile"; then
        echo -e "${CROSS} CRITIQUE: Tag 'latest' trouvé dans $dockerfile"
        ((ERRORS++))
    fi
done
echo -e "${CHECK} Dockerfiles vérifiés"
((SUCCESS++))

# Vérifier que les Dockerfiles utilisent Debian
for dockerfile in srcs/requirements/*/Dockerfile; do
    if ! grep -q "FROM debian:" "$dockerfile" && ! grep -q "FROM alpine:" "$dockerfile"; then
        echo -e "${CROSS} $dockerfile n'utilise pas Debian ou Alpine"
        ((ERRORS++))
    fi
done
echo -e "${CHECK} Images de base correctes"
((SUCCESS++))

echo -e "\n${BLUE}[5/8] Vérification des scripts...${NC}"
if grep -rq "sleep infinity\|tail -f /dev/null\|tail -f /dev/random" srcs/requirements/*/tools/; then
    echo -e "${CROSS} CRITIQUE: Boucles infinies trouvées dans les scripts"
    ((ERRORS++))
else
    echo -e "${CHECK} Pas de boucles infinies dans les scripts"
    ((SUCCESS++))
fi

if grep -rq "\-\-link" srcs/; then
    echo -e "${CROSS} CRITIQUE: '--link' trouvé dans les scripts"
    ((ERRORS++))
else
    echo -e "${CHECK} Pas de '--link' dans les scripts"
    ((SUCCESS++))
fi

echo -e "\n${BLUE}[6/8] Vérification de la configuration WordPress...${NC}"
if grep -qi "WP_ADMIN_USER.*=.*admin" srcs/template.env; then
    echo -e "${CROSS} CRITIQUE: Username admin contient 'admin'"
    ((ERRORS++))
elif grep -qi "WP_ADMIN_USER.*=.*root" srcs/template.env; then
    echo -e "${CROSS} CRITIQUE: Username admin est 'root'"
    ((ERRORS++))
else
    echo -e "${CHECK} Username admin correct (pas 'admin' ou 'root')"
    ((SUCCESS++))
fi

echo -e "\n${BLUE}[7/8] Vérification de la configuration NGINX...${NC}"
if grep -q "ssl_protocols.*TLSv1.2" srcs/requirements/nginx/conf/nginx.conf; then
    echo -e "${CHECK} TLSv1.2 configuré"
    ((SUCCESS++))
else
    echo -e "${CROSS} TLSv1.2 manquant"
    ((ERRORS++))
fi

if grep -q "ssl_protocols.*TLSv1.3" srcs/requirements/nginx/conf/nginx.conf; then
    echo -e "${CHECK} TLSv1.3 configuré"
    ((SUCCESS++))
else
    echo -e "${WARN} TLSv1.3 manquant (optionnel)"
    ((WARNINGS++))
fi

if grep -q "listen.*443.*ssl" srcs/requirements/nginx/conf/nginx.conf; then
    echo -e "${CHECK} NGINX écoute sur le port 443"
    ((SUCCESS++))
else
    echo -e "${CROSS} NGINX n'écoute pas sur le port 443"
    ((ERRORS++))
fi

echo -e "\n${BLUE}[8/8] Vérification de l'environnement...${NC}"
check_warning $(command -v docker >/dev/null 2>&1 && echo 0 || echo 1) "Docker installé"
check_warning $(command -v docker compose >/dev/null 2>&1 && echo 0 || echo 1) "Docker Compose installé"
check_warning $(command -v make >/dev/null 2>&1 && echo 0 || echo 1) "Make installé"

# Vérifier /etc/hosts
if grep -q "yaabdall.42.fr" /etc/hosts; then
    echo -e "${CHECK} Domaine dans /etc/hosts"
    ((SUCCESS++))
else
    echo -e "${WARN} Domaine manquant dans /etc/hosts"
    echo -e "      ${YELLOW}Exécutez: sudo bash -c 'echo \"127.0.0.1 yaabdall.42.fr\" >> /etc/hosts'${NC}"
    ((WARNINGS++))
fi

# Résumé
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         RÉSUMÉ                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Réussites:${NC} $SUCCESS"
echo -e "${YELLOW}Avertissements:${NC} $WARNINGS"
echo -e "${RED}Erreurs:${NC} $ERRORS"

echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ PROJET PRÊT POUR L'ÉVALUATION !                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "\n${YELLOW}Note: Il y a $WARNINGS avertissement(s), mais ils ne bloquent pas l'évaluation.${NC}"
    fi
    
    echo -e "\n${BLUE}Prochaines étapes:${NC}"
    echo "  1. Créer le fichier .env: cp srcs/template.env srcs/.env"
    echo "  2. Modifier les mots de passe dans srcs/.env"
    echo "  3. Vérifier /etc/hosts: cat /etc/hosts | grep yaabdall"
    echo "  4. Lancer: make"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ ERREURS CRITIQUES DÉTECTÉES !                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${RED}Veuillez corriger les erreurs avant l'évaluation.${NC}"
    echo -e "${RED}L'évaluation serait arrêtée immédiatement avec une note de 0.${NC}\n"
    exit 1
fi
