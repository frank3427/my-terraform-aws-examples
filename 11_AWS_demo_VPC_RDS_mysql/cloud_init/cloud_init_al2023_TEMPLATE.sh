#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
dnf install mariadb105-server nmap -y 

echo "========== Create a script to connect to MySQL Database"
cat << EOF > /home/ec2-user/mysql.sh
mysql -u ${param_user} -h ${param_hostname}
EOF
chown ec2-user:ec2-user /home/ec2-user/mysql.sh
chmod 700 /home/ec2-user/mysql.sh

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot