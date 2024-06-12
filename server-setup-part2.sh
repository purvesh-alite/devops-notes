#!/bin/bash

set -e

DOMAIN=$1 # Accept the domain name as the first argument

# Install Certbot and configure SSL
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m user@domain.com

figlet "Nginx Setup Complete"
export DOCKER_HUB_USERNAME=purveshpanchal
export DOCKER_HUB_PASSWORD="Alite@123"
# Log in to Docker Hub
docker login -u ${DOCKER_HUB_USERNAME} -p ${DOCKER_HUB_PASSWORD}

# Pull and run the application container
docker pull purveshpanchal/tf-meteor:jenkins 
docker run --name tf-meteor -dp 3000:3000 -e MONGO_HOST=`hostname -I | awk '{print $1}'` purveshpanchal/tf-meteor:v4

figlet "Deployed Successfully!"
echo "-----> $DOMAIN"
