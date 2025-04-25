#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
dnf install zsh nmap postgresql15 -y

echo "========== Create a script to connect to PostgreSQL Database"
cat << EOF > /home/ec2-user/psql.sh
SQL_FILE=\$1
if [ "\$SQL_FILE" != "" ]; then 
    psql -h ${param_hostname} -d ${param_db_name} -U ${param_user} -f \$SQL_FILE
else
    psql -h ${param_hostname} -d ${param_db_name} -U ${param_user}
fi
EOF
chown ec2-user:ec2-user /home/ec2-user/psql.sh
chmod 700 /home/ec2-user/psql.sh

cat << EOF > /home/ec2-user/.pgpass
${param_hostname}:5432:${param_db_name}:${param_user}:${param_password}
EOF
chown ec2-user:ec2-user /home/ec2-user/.pgpass
chmod 600 /home/ec2-user/.pgpass

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot