#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
amazon-linux-extras enable postgresql14
yum install zsh postgresql nmap -y

echo "========== Create a script to connect to PostgreSQL Database"
cat << EOF > /home/ec2-user/psql.sh
psql -h ${param_hostname} -d ${param_db_name} -U ${param_user} -W 
EOF
chown ec2-user:ec2-user /home/ec2-user/psql.sh
chmod 700 /home/ec2-user/psql.sh

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot