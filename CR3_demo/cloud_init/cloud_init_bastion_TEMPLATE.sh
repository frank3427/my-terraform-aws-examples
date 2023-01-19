#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== set a meaningful hostname"
hostnamectl set-hostname bastion
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "========== Install some packages"
yum install zsh nmap -y

echo "========== Mount the EFS filesystem using EFS mount helper"
yum install -y amazon-efs-utils
mkdir -p ${mount_point}
echo "${dns_name}:/  ${mount_point}    efs       tls,defaults,noatime,_netdev      0      0"  >> /etc/fstab
sleep 60
while (true)
do
    mount ${mount_point}
    if [ $? -eq 0 ]; then break; fi
    sleep 10
done
chown ec2-user:ec2-user ${mount_point}

echo "========== Store web pages on EFS filesystem"
mkdir -p ${mount_point}/var_www_html

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot