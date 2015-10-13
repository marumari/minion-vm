#!/usr/bin/env bash

# The base directory for large pieces of the install
MINION_BASE_DIRECTORY=/opt/minion

# Install common packages
apt-get update && apt-get -y install build-essential \
    git \
    libssl-dev \
    python \
    python-dev \
    python-virtualenv \
    supervisor

# We install supervisor, but we don't actually need it to startup: /etc/init.d/minion already does that
update-rc.d -f supervisor remove

# Create the Minion directory if it doesn't exist, like in Docker
if [[ ! -d "${MINION_BASE_DIRECTORY}" ]]; then
    mkdir -p "${MINION_BASE_DIRECTORY}"
fi

cd ${MINION_BASE_DIRECTORY}

# First, create and activate the virtualenv; we do this outside of the shared directory
virtualenv minion-env
source minion-env/bin/activate

# Upgrade setuptools to the newest version
easy_install --upgrade setuptools

# Create minion user account
useradd -m minion

# Create all the running directories for minion, locking things down as needed
install -m 700 -o minion -g minion \
    -d /run/minion -d /var/lib/minion -d /var/log/minion -d ~minion/.python-eggs
install -m 710 -o root -g minion -d /etc/minion

# Setup the minion environment for the minion user
echo -e "\n# Source minion-backend virtualenv\nsource ${MINION_BASE_DIRECTORY}/minion-env/bin/activate" >> ~minion/.profile
