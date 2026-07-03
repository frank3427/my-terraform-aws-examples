#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
dnf install zsh nmap -y

echo "========== Install Docker"
dnf install docker -y
systemctl enable docker --now
usermod -a -G docker ec2-user

# echo "========== Install latest updates"
# dnf update -y

# echo "========== Final reboot"
# reboot
