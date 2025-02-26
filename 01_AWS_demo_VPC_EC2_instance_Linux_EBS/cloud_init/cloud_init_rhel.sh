#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Create a filesystem on the additional EBS volume"
mkfs -t xfs -L ebsvol1 /dev/sdf       # symlink to /dev/nvme1n1 or to /dev/xvdf
echo "LABEL=ebsvol1  /mnt/ebs1    xfs       defaults,noatime,_netdev      0      0"  >> /etc/fstab
mkdir -p /mnt/ebs1
mount /mnt/ebs1
chown ec2-user:ec2-user /mnt/ebs1

echo "========== Install some packages"
yum install zsh nmap -y

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot