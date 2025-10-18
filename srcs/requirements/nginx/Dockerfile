FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

# genere le certificat ssl
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/nginx.key \
	-out /etc/nginx/ssl/nginx.crt \
	-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=yaabdall.42.fr"

# Copie le fichier de configuration nginx
COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

# Lance nginx en avant plan pour que le container reste actif
CMD ["nginx", "-g", "daemon off;"]
