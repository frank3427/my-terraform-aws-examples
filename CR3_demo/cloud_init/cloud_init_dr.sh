#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== set a meaningful hostname"
hostnamectl set-hostname webserver-dr
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "========== Install Apache Web server with PHP support plus other packages"
yum -y install httpd php zsh nmap

echo "========== Start Apache Web server with PHP support"
systemctl start httpd
systemctl enable httpd

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot