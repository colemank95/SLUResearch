#!/bin/bash

# Check that user is root

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Inform user that they must use Ubuntu 14.xx

while true; do
    read -p "Are you using Ubuntu 14.xx? This will not work on any other versions." yn
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

