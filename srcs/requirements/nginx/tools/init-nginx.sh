#!/bin/bash
set -e

# Generate SSL certificates if they don't exist
if [ ! -f "/etc/nginx/ssl/${DOMAIN_NAME}.key" ] || [ ! -f "/etc/nginx/ssl/${DOMAIN_NAME}.crt" ]; then
	echo "🔐 Generating SSL certificate for ${DOMAIN_NAME}..."
	
	mkdir -p /etc/nginx/ssl
	
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout "/etc/nginx/ssl/${DOMAIN_NAME}.key" \
		-out "/etc/nginx/ssl/${DOMAIN_NAME}.crt" \
		-subj "/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}"
	
	echo "✅ SSL certificate generated for ${DOMAIN_NAME}"
fi

# Generate NGINX configuration from template with environment variables
echo "⚙️ Generating NGINX configuration for ${DOMAIN_NAME}..."
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
echo "✅ NGINX configuration generated"

# Validate NGINX configuration
echo "🔍 Validating NGINX configuration..."
if ! nginx -t 2>&1 | grep -q "successful"; then
	echo "❌ NGINX configuration error!"
	nginx -t
	exit 1
fi
echo "✅ NGINX configuration is valid"

# Start NGINX in foreground
echo "🚀 Starting NGINX..."
exec nginx -g "daemon off;"
