#!/bin/bash

url_mime="ftp://ftp.ateme.com/JMH/Origin/mime.types"
url_nginx="ftp://ftp.ateme.com/JMH/Origin/nginx.conf"

username="nginx"
password="password"

sudo apt-get -y update
sudo apt -y install nginx


sudo systemctl enable nginx 

cd /etc/nginx
sudo rm mime.types
sudo rm nginx.conf

sudo wget $url_mime
sudo wget $url_nginx

pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
sudo useradd -m -p "$pass" "$username"

sudo systemctl restart nginx