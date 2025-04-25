#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
yum install zsh nmap telnet -y

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot