#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
apt-get update
apt-get install nmap zsh -y

echo "========== Install latest updates"
apt-get upgrade -y

echo "========== Final reboot"
reboot