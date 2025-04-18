#!/bin/bash

echo "First arg: $1"    # banana
echo "Second arg: $2"   # apple

# This script is used to provision a Vagrant VM with a specific configuration.
# It installs necessary packages, sets up the environment, and configures the VM.
# Update the package list

apt-get update -y
apt-get install -y \
    curl \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg \
    lsb-release \
    nginx

# Override default nginx.conf [disable sendfile due to issues with Docker]
cat << 'EOF' > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {
        ##
        # Basic Settings
        ##

        sendfile off;
        tcp_nopush on;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;


        ##
        # SSL Settings
        ##

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        ##
        # Logging Settings
        ##

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        ##
        # Gzip Settings
        ##

        gzip on;

        # gzip_vary on;
        # gzip_proxied any;
        # gzip_comp_level 6;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

        ##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;


        server {
            listen 80;
            server_name localhost;

            location / {
                proxy_pass http://localhost:8080;  # Forward to Docker container
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }        

}
EOF

cat << 'EOF' > /etc/nginx/sites-available/reverse-proxy
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
# Create a symbolic link to enable the site
ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/

# Remove the default site configuration to avoid conflicts
rm -f /etc/nginx/sites-enabled/default
        
# Test nginx configuration
systemctl reload nginx || nginx -s reload


# Add Docker GPG key and repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
      
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      
apt-get update -y
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin
    
      
# Install docker-compose (v2 CLI as fallback)
VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K[^"]+')
[ -z "$VERSION" ] && VERSION="v2.24.2"
      
DESTINATION=/usr/local/bin/docker-compose
curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o "$DESTINATION"
chmod +x "$DESTINATION"
      
# Ensure it's an ELF binary
file "$DESTINATION" | grep -q 'ELF' || { echo "❌ Invalid Docker Compose binary downloaded"; exit 1; }
      
# Enable Docker API on TCP
mkdir -p /etc/systemd/system/docker.service.d
cat << "EOF" > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
EOF
   
# Add vagrant to docker group
getent group docker || groupadd docker
usermod -aG docker vagrant

# Reload systemd and restart Docker
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart docker