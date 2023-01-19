#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install AWS CLI v2 for linux x86_64 arch"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

echo "========== Install some packages"
yum install zsh nmap -y

echo "========== Install latest updates"
yum update -y

echo "========== Final reboot"
reboot