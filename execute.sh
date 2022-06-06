#!/bin/bash
sudo apt-get update
sudo apt install -y  awscli
sudo snap install docker
#curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
#sudo apt install -y  nodejs
mkdir -p /home/ubuntu/application
cd /home/ubuntu/application
touch start
aws s3 cp   s3://cpe-appserver-bucket/app_dir/docker-compose.yml  /home/ubuntu/application/docker-compose.yml
aws s3 cp   s3://cpe-appserver-bucket/app_dir/app  /home/ubuntu/application/app  --recursive
aws s3 cp   s3://cpe-appserver-bucket/app_dir/nginx /home/ubuntu/application/nginx --recursive
touch stop
sudo chown -R  ubuntu /home/ubuntu/application
sudo docker-compose up -d --scale web=1

