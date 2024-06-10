#!/bin/bash

set -e

DOMAIN=$1 # Accept the domain name as the first argument

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y nginx curl gnupg docker.io figlet

figlet "Docker"
# Setup Docker permissions
sudo usermod -aG docker ${USER}
sudo chmod 666 /var/run/docker.sock

echo "----------- $DOMAIN ------------"
echo $DOMAIN
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

cat /etc/nginx/sites-enabled/*.com
figlet "Nginx"
sudo nginx -t
sudo systemctl restart nginx

figlet "Setup Part 1 Complete"
echo "Please update your DNS records to point to the public IP address of the instance."
echo `curl -s 2ip.io`
