#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
yum install zsh mysql nmap -y

echo "========== Get global Cert for RDS"
curl https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /home/ec2-user/global-bundle.pem

echo "========== Create a script to connect to MySQL Database"
cat << EOF > /home/ec2-user/mysql.sh
mysql -u ${param_user} -p -h ${param_hostname}
EOF
cat << EOF > /home/ec2-user/mysql_enc.sh
mysql -u ${param_user} -p -h ${param_hostname} --ssl-ca=global-bundle.pem --ssl-verify-server-cert
EOF
chown ec2-user:ec2-user /home/ec2-user/mysql.sh /home/ec2-user/mysql_enc.sh
chmod 700 /home/ec2-user/mysql.sh /home/ec2-user/mysql_enc.sh

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot