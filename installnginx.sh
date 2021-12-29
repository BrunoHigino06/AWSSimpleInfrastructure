#! /bin/bash
sudo yum -y update
sudo yum -y upgrade
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx