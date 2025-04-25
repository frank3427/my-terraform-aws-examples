#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Create a filesystem on the additional EBS volume"
mkfs -t xfs -L ebsvol1 /dev/nvme1n1
echo "LABEL=ebsvol1  /mnt/ebs1    xfs       defaults,noatime,_netdev      0      0"  >> /etc/fstab
mkdir -p /mnt/ebs1
mount /mnt/ebs1

echo "========== Install some packages"
apt-get update
apt-get install nmap zsh -y

echo "========== Install latest updates"
apt-get upgrade -y

echo "========== Final reboot"
reboot