#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install Oracle Instant Client 21c"
wget https://download.oracle.com/otn_software/linux/instantclient/218000/oracle-instantclient-basic-21.8.0.0.0-1.x86_64.rpm
wget https://download.oracle.com/otn_software/linux/instantclient/218000/oracle-instantclient-sqlplus-21.8.0.0.0-1.x86_64.rpm
wget https://download.oracle.com/otn_software/linux/instantclient/218000/oracle-instantclient-tools-21.8.0.0.0-1.x86_64.rpm
yum install -y ./oracle-instantclient-basic-21.8.0.0.0-1.x86_64.rpm
yum install -y ./oracle-instantclient-tools-21.8.0.0.0-1.x86_64.rpm 
yum install -y ./oracle-instantclient-sqlplus-21.8.0.0.0-1.x86_64.rpm

echo "========== Configure Oracle Instant client for ec2-user"
mkdir -p /home/ec2-user/oradb

cat << EOF >> /home/ec2-user/.bash_profile
export PATH=\$PATH:/usr/lib/oracle/21/client64/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib/oracle/21/client64/lib
export TNS_ADMIN=/home/ec2-user/oradb
echo "Oracle Instant Client 21c installed"
echo
EOF

cat << EOF >> /home/ec2-user/oradb/tnsnames.ora
${param_alias} = (DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)
   (HOST = ${param_hostname}) (PORT = 1521)))(CONNECT_DATA = (SID = ${param_sid})))
EOF

chmod 700 /home/ec2-user/oradb
chown -R ec2-user:ec2-user /home/ec2-user/oradb

echo "========== Create a script to connect to Oracle Database with sqlplus"
cat << EOF > /home/ec2-user/sqlplus.sh
sqlplus ${param_user}@${param_alias}
EOF
chown ec2-user:ec2-user /home/ec2-user/sqlplus.sh
chmod 700 /home/ec2-user/sqlplus.sh

echo "========== Install some packages"
yum install zsh nmap -y

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot