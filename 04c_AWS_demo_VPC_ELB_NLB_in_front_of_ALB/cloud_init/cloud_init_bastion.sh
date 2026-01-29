#!/bin/bash

# Send stdout and stderr to /var/log/cloud-init2.log
exec > /var/log/cloud-init2.log 2>&1

echo "=== Cloud-init script STARTED ==="
date

# Install packages
yum update -y
yum install -y htop

echo "=== Cloud-init script COMPLETED ==="
date
