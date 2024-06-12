#!/bin/bash

# MongoDB admin user credentials
ADMIN_USER="admin"
ADMIN_PASS="p4ssw0rd"

# Log file for script output
LOG_FILE="logs-of-script.txt"

#!/bin/bash
sudo apt-get install gnupg curl

wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

sudo dpkg -i libssl1.1*

sudo rm libssl1.1_1.1.0g-2ubuntu4_amd64.deb
# Import the MongoDB public GPG Key
curl -fsSL https://pgp.mongodb.com/server-4.4.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-4.4.gpg \
   --dearmor

# Create a list file for MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Update package list and install MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# Pin MongoDB packages to avoid unwanted upgrades
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-org-shell hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

#Confirm Installation by checking version
mongo --version

# Start MongoDB service
sudo systemctl start mongod

# Enable MongoDB to start on boot
sudo systemctl enable mongod

# Check MongoDB status
sudo systemctl status mongod

figlet "MongoDB 4.4 installation completed successfully."

# Ensure MongoDB data directory exists and has proper permissions
DB_PATH="/home/$USER/mongodb"
if [ ! -d "$DB_PATH" ]; then
    echo "Creating MongoDB data directory at $DB_PATH..." | tee -a $LOG_FILE
    mkdir -p "$DB_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to create MongoDB data directory. Continuing script. Check the logs for details." | tee -a $LOG_FILE
    fi
fi

# Ensure MongoDB log directory exists and has proper permissions
LOG_DIR="/var/log/mongodb"
if [ ! -d "$LOG_DIR" ]; then
    echo "Creating MongoDB log directory at $LOG_DIR..." | tee -a $LOG_FILE
    sudo mkdir -p "$LOG_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create MongoDB log directory. Continuing script. Check the logs for details." | tee -a $LOG_FILE
    fi
fi

# Set proper permissions for MongoDB log directory
echo "Setting permissions for MongoDB log directory..." | tee -a $LOG_FILE
sudo chown -R $USER:$USER "$LOG_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to set permissions for MongoDB log directory. Continuing script. Check the logs for details." | tee -a $LOG_FILE
fi

# Step 1: Start MongoDB without authentication
echo "Starting MongoDB without authentication..." | tee -a $LOG_FILE
mongod --fork --logpath $LOG_DIR/mongod.log --dbpath "$DB_PATH" --bind_ip_all
if [ $? -ne 0 ]; then
    echo "Error starting MongoDB. Check the log at $LOG_DIR/mongod.log for details. Continuing script." | tee -a $LOG_FILE
fi

# Give MongoDB some time to start
sleep 5

# Step 2: Create admin user
echo "Creating admin user..." | tee -a $LOG_FILE
mongo admin --eval "db.createUser({user: '$ADMIN_USER', pwd: '$ADMIN_PASS', roles: [{ role: 'root', db: 'admin' }]})"
if [ $? -ne 0 ]; then
    echo "Error creating admin user. Continuing script. Check the logs for details." | tee -a $LOG_FILE
fi

# Step 2.5: Create user
echo "Creating database..." | tee -a $LOG_FILE
mongo --eval "db.getSiblingDB('wp').createUser({user: 'user', pwd: 'password', roles: [{ role: 'readWrite', db: 'wp' }]})" -u $ADMIN_USER -p $ADMIN_PASS

mongo --eval "db.getSiblingDB('wp').createCollection('test')" -u $ADMIN_USER -p $ADMIN_PASS


# Step 3: Stop MongoDB
echo "Stopping MongoDB..." | tee -a $LOG_FILE
mongod --shutdown
if [ $? -ne 0 ]; then
    echo "Error stopping MongoDB. Continuing script. Check the logs for details." | tee -a $LOG_FILE
fi

# Step 4: Update mongod.conf for authentication
echo "Updating mongod.conf..." | tee -a $LOG_FILE
sudo tee /etc/mongod.conf > /dev/null <<EOF
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled
#  keyFile: /etc/mongodb/keys/mongo-key
#  transitionToAuth: true

#operationProfiling:

#replication:

#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:
EOF
if [ $? -ne 0 ]; then
    echo "Error updating mongod.conf. Continuing script. Check the logs for details." | tee -a $LOG_FILE
fi

# Step 5: Restart MongoDB service with authentication enabled
echo "Restarting MongoDB service with authentication..." | tee -a $LOG_FILE
sudo systemctl restart mongod
if [ $? -ne 0 ]; then
    echo "Error restarting MongoDB service. Check the log at $LOG_DIR/mongod.log for details. Continuing script." | tee -a $LOG_FILE
fi
sudo service mongod status
figlet "MongoDB Setup completed successfully." | tee -a $LOG_FILE
