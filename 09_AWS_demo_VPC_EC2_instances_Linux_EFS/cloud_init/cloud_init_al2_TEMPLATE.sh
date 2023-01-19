#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Mount the EFS filesystem using EFS mount helper"
yum install -y amazon-efs-utils
mkdir -p ${mount_point}
echo "${dns_name}:/  ${mount_point}    efs       tls,defaults,noatime,_netdev      0      0"  >> /etc/fstab
mount ${mount_point}

echo "========== Install some packages"
yum install zsh nmap -y

echo "========== Install latest updates"
yum update -y

echo "========== Final reboot"
reboot