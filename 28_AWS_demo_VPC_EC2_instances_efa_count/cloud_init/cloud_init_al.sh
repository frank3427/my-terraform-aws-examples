#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
yum install zsh nmap -y

echo "========== Install EFA software, including Open MPI"
curl -o /tmp/aws-efa-installer.zip -O https://efa-installer.amazonaws.com/aws-efa-installer-1.27.0.tar.gz
cd /home/ec2-user
tar xf /tmp/aws-efa-installer.zip
cd aws-efa-installer
./efa_installer.sh -y

# disable ptrace protection
sysctl -w kernel.yama.ptrace_scope=0    
echo "kernel.yama.ptrace_scope = 0" >> /etc/sysctl.d/10-ptrace.conf

echo "export PATH=\$PATH:/opt/amazon/openmpi/bin:/opt/amazon/efa/bin" >> /home/ec2-user/.bashrc

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot