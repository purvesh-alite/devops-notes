#!/bin/bash

set -e

DOMAIN=$1 # Accept the domain name as the first argument

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y nginx curl gnupg docker.io figlet

# Setup Docker permissions
sudo usermod -aG docker ${USER}
sudo chmod 666 /var/run/docker.sock

# Configure Nginx
sudo tee /etc/nginx/sites-enabled/$DOMAIN > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

figlet "Nginx"
sudo nginx -t
sudo systemctl restart nginx

# Install Certbot and configure SSL
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m user@domain.com

figlet "Setup Complete"
export DOCKER_HUB_USERNAME=purveshpanchal
export DOCKER_HUB_PASSWORD="Alite@123"
# Log in to Docker Hub
docker login -u ${DOCKER_HUB_USERNAME} -p ${DOCKER_HUB_PASSWORD}

# Pull and run the application container
docker pull purveshpanchal/tf-meteor:jenkinsyour-dockerhub-username/your-app-image:latest
docker run -d --name tf-meteor -p 3000:3000 purveshpanchal/tf-meteor:jenkins
