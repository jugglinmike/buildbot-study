#!/usr/bin/env bash

set -e

BOT_USER=${BOT_USER:-buildbot}

echo "Updating package repository"
# As of this writing, Utopic is the only Ubuntu release with the latest version
# of BuildBot (0.8.9)
cat <<EOF >> /etc/apt/sources.list
deb http://us.archive.ubuntu.com/ubuntu/ utopic universe
deb-src http://us.archive.ubuntu.com/ubuntu/ utopic universe
EOF
sudo apt-get update >/dev/null 2>&1

echo "Installing dependencies"
#sudo apt-get install -y git build-essential python-dev python-pip >/dev/null 2>&1
sudo apt-get install -y git buildbot/utopic >/dev/null 2>&1

echo "Configuring build master"
cd /var/lib/buildbot/masters
sudo buildbot create-master master
sudo ln -s /vagrant/master.cfg master
sudo chown -R buildbot:buildbot master
sudo cp /vagrant/daemons/buildmaster /etc/default

sudo /etc/init.d/buildmaster start

echo "Configuring build slave"
cd /var/lib/buildbot/slaves
sudo buildslave create-slave slave localhost:9989 \
  example-slave pass
sudo chown -R buildbot:buildbot slave
sudo cp /vagrant/daemons/buildslave /etc/default

sudo /etc/init.d/buildslave start

echo "Installing Builder Dependencies"

echo ">>> Node.js"
mkdir -p /opt/joyent/node
cd /opt/joyent/node
wget http://nodejs.org/dist/v0.10.30/node-v0.10.30-linux-x64.tar.gz \
  --output-document nodejs.tar.gz >/dev/null 2>&1
tar --strip-components=1 -xf nodejs.tar.gz
rm nodejs.tar.gz
ln -s /opt/joyent/node/bin/node /usr/local/bin
ln -s /opt/joyent/node/bin/npm /usr/local/bin
chown -R buildbot .

echo ">>> xvfb"
sudo apt-get install -y xvfb >/dev/null 2>&1

echo ">>> Google Chrome"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb  >/dev/null 2>&1
if ! sudo dpkg -i google-chrome-stable_current_amd64.deb >/dev/null 2>&1; then
  sudo apt-get install -f -y >/dev/null 2>&1
  sudo dpkg -i google-chrome-stable_current_amd64.deb >/dev/null 2>&1
fi
sudo rm google-chrome-stable_current_amd64.deb
