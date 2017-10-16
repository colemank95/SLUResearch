#!/bin/bash

# Check that user is root

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Inform user that they must use Ubuntu 14.xx

while true; do
    read -p "Are you using Ubuntu 14.xx? This will not work on any other versions.[y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


# 

apt-get update

apt-get upgrade


apt-get install git -y

cd

git clone https://github.com/apache/incubator-openwhisk.git openwhisk

cd openwhisk

cd tools/ubuntu-setup

./all.sh

apt-get install -V couchdb


echo "root=password" >> /etc/couchdb/local.ini 


sed -i -e 's/bind_address = 127.0.0.1/bind_address = 0.0.0.0/g' /etc/couchdb/default.ini

restart couchdb


sudo apt-get install python-pip
sudo pip install ansible==2.3.0.0
sudo pip install jinja2==2.9.6

cd 

cd openwhisk/ansible

ansible-playbook initdb.yml

export OW_DB=CouchDB
export OW_DB_USERNAME=root	
export OW_DB_PASSWORD=password
export OW_DB_PROTOCOL=http
export OW_DB_HOST=ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
export OW_DB_PORT=5984

ansible-playbook setup.yml


cd

cd openwhisk

./gradlew distDocker

cd ansible


ansible-playbook couchdb.yml
ansible-playbook initdb.yml
ansible-playbook wipe.yml
ansible-playbook apigateway.yml
ansible-playbook openwhisk.yml
ansible-playbook postdeploy.yml

