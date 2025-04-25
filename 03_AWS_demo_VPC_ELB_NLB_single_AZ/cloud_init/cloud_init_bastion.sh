#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== set a meaningful hostname"
hostnamectl set-hostname bastion
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "========== Install some package"
yum install nmap -y

echo "========== Apply latest updates to Linux OS"
yum update -y

echo "========== Final reboot"
reboot