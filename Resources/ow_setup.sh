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

apt-get install docker-ce -y

# install git and clone openwhisk repo to home directory

apt-get install git -y

apt-get install vim -y

cd

git clone https://github.com/apache/incubator-openwhisk.git openwhisk

groupadd docker

sudo usermod -aG docker $USER

# run initial setup for ubuntu native development tools

cd openwhisk

cd tools/ubuntu-setup

./all.sh

# install and setup couchdb

apt-get install -V couchdb

# feel free to chane this username and password to something more secure
# you will need to reflect those changes in the env vars below

echo "root=password" >> /etc/couchdb/local.ini 

# use sed to find and replace the default localhost IP with 0.0.0.0 in default.ini

sed -i -e 's/bind_address = 127.0.0.1/bind_address = 0.0.0.0/g' /etc/couchdb/default.ini

restart couchdb

apt-get install python-pip -y
yes | pip install ansible==2.3.0.0 -y
yes | pip install jinja2==2.9.6 -y

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

ansible-playbook setup.yml

# build and deploy using ansible 

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
