#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Download the Amazon DocumentDB Certificate Authority (CA) certificate required to authenticate to your cluster"
wget -O /home/ec2-user/global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

echo "========== Create a script to connect to DocumentDB cluster"
cat << EOF > /home/ec2-user/docdb.sh
mongosh --tls \\
        --tlsCAFile /home/ec2-user/global-bundle.pem \\
        --authenticationDatabase admin \\
        --username ${param_user} \\
        --password ${param_passwd} \\
        "mongodb://${param_hostname}:${param_port}?retryWrites=false"
EOF
chown ec2-user:ec2-user /home/ec2-user/docdb.sh
chmod 700 /home/ec2-user/docdb.sh

# https://www.mongodb.com/docs/mongodb-shell/install/
echo "========== Wait for any ongoing dnf/yum process to finish"
while fuser /var/lib/rpm/.rpm.lock >/dev/null 2>&1; do
  echo "Waiting for RPM lock to be released..."
  sleep 5
done

echo "========== Install mongo shell"
cat << EOF > /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
dnf install -y mongodb-mongosh

echo "========== Install some packages"
dnf install nmap -y

# echo "========== Install latest updates"
# dnf update -y

# echo "========== Final reboot"
# reboot

echo "========== End of Cloud-init"
