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


# install Docker

apt-get update

apt-get upgrade

apt-get update

apt-get install \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual -y 

apt-get update

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common -y

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-get update

sudo apt-get install docker-ce -y


groupadd docker

sudo usermod -aG docker $USER

# install git and clone openwhisk repo to home directory

sudo apt-get install git -y

sudo apt-get install vim -y

cd

git clone https://github.com/apache/incubator-openwhisk.git openwhisk

# run initial setup for ubuntu native development tools

cd openwhisk

cd tools/ubuntu-setup

sudo ./all.sh

# install and setup couchdb

sudo apt-get install -V couchdb -y

# feel free to chane this username and password to something more secure
# you will need to reflect those changes in the env vars below

echo "root=password" >> /etc/couchdb/local.ini 

# use sed to find and replace the default localhost IP with 0.0.0.0 in default.ini

sed -i -e 's/bind_address = 127.0.0.1/bind_address = 0.0.0.0/g' /etc/couchdb/default.ini

restart couchdb

sudo apt-get install python-pip -y
sudo pip install ansible==2.3.0.0 
sudo pip install jinja2==2.9.6 

cd 

cd openwhisk/ansible

# init db 

ansible-playbook initdb.yml

# export OW_DB env vars. if you changed username and password for couchdb above, change it here also

export OW_DB=CouchDB
export OW_DB_USERNAME=root	
export OW_DB_PASSWORD=password
export OW_DB_PROTOCOL=http
export OW_DB_HOST=ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
export OW_DB_PORT=5984

sudo ansible-playbook setup.yml

# build and deploy using ansible 

cd

cd openwhisk

./gradlew distDocker

cd ansible

sudo ansible-playbook couchdb.yml
sudo ansible-playbook initdb.yml
sudo ansible-playbook wipe.yml
sudo ansible-playbook apigateway.yml
sudo ansible-playbook openwhisk.yml
sudo ansible-playbook postdeploy.yml
