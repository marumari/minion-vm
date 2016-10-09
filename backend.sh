#!/usr/bin/env bash

: ${MINION_ADMINISTRATOR_EMAIL?"Need to add MINION_ADMINISTRATOR_EMAIL to environment.  Check docker-compose.yml build args or pass on CLI."}
: ${MINION_ADMINISTRATOR_NAME?"Need to add MINION_ADMINISTRATOR_NAME to environment.  Check docker-compose.yml build args or pass on CLI."}

# The base directory for large pieces of the install
MINION_BASE_DIRECTORY=/opt/minion

## Gets around prompt during build of backend container asking for Postfix configuration
echo "postfix postfix/mailname string your.hostname.com" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'No configuration'" | debconf-set-selections

## Install backend only packages
apt -y install curl \
  libcurl4-openssl-dev \
  libffi-dev \
  mongodb-server \
  nmap \
  postfix \
  rabbitmq-server \
  stunnel
apt clean

# First, source the virtualenv
cd ${MINION_BASE_DIRECTORY}
source minion-env/bin/activate

# Next, let's install minion-backend

# Uncomment this line if you don't have a local working copy on your local system
# git clone https://github.com/mozilla/minion-backend.git ${MINION_BASE_DIRECTORY}/minion-backend
cd minion-backend
python setup.py develop

# Configure minion-backend (listening on 0.0.0.0:8383, and with no blacklist)
mkdir -p /etc/minion
mv /tmp/scan.json /etc/minion

# Install minion-nmap-plugin; comment out `git clone` if working on minion-nmap-plugin locally
# via Vagrant synced folder
git clone https://github.com/mozilla/minion-nmap-plugin ${MINION_BASE_DIRECTORY}/minion-nmap-plugin
cd ${MINION_BASE_DIRECTORY}/minion-nmap-plugin
python setup.py install

# Add the minion init scripts to the system startup scripts
cp ${MINION_BASE_DIRECTORY}/minion-backend/scripts/minion-init /etc/init.d/minion
chown root:root /etc/init.d/minion
chmod 755 /etc/init.d/minion
update-rc.d minion defaults 40

# Setup the minion environment for the minion user
echo -e "\n# Minion convenience commands" >> ~minion/.bashrc
echo -e "alias miniond=\"supervisord -c ${MINION_BASE_DIRECTORY}/minion-backend/etc/supervisord.conf\"" >> ~minion/.bashrc
echo -e "alias minionctl=\"supervisorctl -c ${MINION_BASE_DIRECTORY}/minion-backend/etc/supervisord.conf\"" >> ~minion/.bashrc

# Start MongoDB
service mongodb start
sleep 5

# Start RabbitMQ
service rabbitmq-server start
sleep 5

# Start Minion
service minion start
sleep 30

# Create the initial administrator and database
minion-db-init "$MINION_ADMINISTRATOR_EMAIL" "$MINION_ADMINISTRATOR_NAME" y

# If we're running in Docker, we start these with CMD
if [[ $MINION_DOCKERIZED == "true" ]]; then
  service minion stop
  sleep 30
  service rabbitmq-server stop
  sleep 5

  # This seems to be broken on Ubuntu 14.04, since it doesn't create the /var/run/mongodb directory
  # service mongodb stop
  kill `ps aux | grep mongod | grep -v grep | tr -s ' ' | cut -d ' ' -f 2`
fi
