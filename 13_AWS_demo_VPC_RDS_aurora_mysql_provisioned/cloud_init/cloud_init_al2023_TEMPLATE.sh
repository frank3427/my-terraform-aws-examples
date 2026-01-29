#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
dnf install zsh mariadb105-server nmap -y 

# use $$ to ignore shell variable
echo "========== Create a script to connect to MySQL Database"
cat << EOF > /home/ec2-user/mysql.sh
mysql -u ${param_user} -p$${MYSQL_PASSWD} -h ${param_hostname}
EOF
chown ec2-user:ec2-user /home/ec2-user/mysql.sh
chmod 700 /home/ec2-user/mysql.sh

# echo "========== Install latest updates"
# dnf update -y

# echo "========== Final reboot"
# reboot