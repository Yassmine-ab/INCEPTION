FROM debian:bullseye

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	curl \
	&& rm -rf /var/lib/apt/lists/*

# Create SSL certificate directory
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/nginx.key \
	-out /etc/nginx/ssl/nginx.crt \
	-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=yaabdall.42.fr"

# Copy nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create directory for PID file
RUN mkdir -p /run/nginx

# Expose HTTPS port
EXPOSE 443

# Start nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]
