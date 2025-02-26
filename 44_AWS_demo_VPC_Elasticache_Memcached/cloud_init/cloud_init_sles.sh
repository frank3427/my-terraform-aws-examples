#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
zypper install nmap zsh telnet -y

echo "========== Install latest updates"
zypper refresh
zypper --non-interactive update

echo "========== Final reboot"
reboot