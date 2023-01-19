#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

# echo "========== Mount the EFS filesystem using EFS mount helper"
# apt-get -y install git binutils nfs-common
# cd /tmp
# git clone https://github.com/aws/efs-utils
# cd efs-utils
# ./build-deb.sh
# apt-get -y install ./build/amazon-efs-utils*deb
# PROBLEM: stunnel4 not found
# mkdir -p ${mount_point}
# echo "${dns_name}:/  ${mount_point}    efs       tls,defaults,noatime,_netdev      0      0"  >> /etc/fstab
# mount ${mount_point}

# echo "========== Install some packages"
# apt-get update
# apt-get install nmap zsh -y

# echo "========== Install latest updates"
# apt-get upgrade -y

# echo "========== Final reboot"
# reboot