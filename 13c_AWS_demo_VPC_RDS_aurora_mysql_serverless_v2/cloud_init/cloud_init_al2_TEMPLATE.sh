#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
yum install zsh nmap -y

echo "========== Install MySQL client (not available in AL2023)"
# https://dev.to/aws-builders/installing-mysql-on-amazon-linux-2023-1512
wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm -O /tmp/mysql80-community-release-el9-1.noarch.rpm
dnf install /tmp/mysql80-community-release-el9-1.noarch.rpm -y
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf install mysql-community-client -y

# use $$ to ignore shell variable
echo "========== Create a script to connect to MySQL Database"
cat << EOF > /home/ec2-user/mysql.sh
mysql -u ${param_user} -p$${MYSQL_PASSWD} -h ${param_hostname}
EOF
chown ec2-user:ec2-user /home/ec2-user/mysql.sh
chmod 700 /home/ec2-user/mysql.sh

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot