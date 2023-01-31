#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

sleep 60

echo "========== set a meaningful hostname"
hostnamectl set-hostname webserver${ws_nb}
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "========== Install Apache Web server with PHP support + misc packages"
while (true)
do
    yum install zsh nmap httpd php amazon-efs-utils -y
    if [ $? -eq 0 ]; then break; fi
    echo "ERROR yum install, will try again in 10 seconds..."
    sleep 10
done

echo "========== Mount the EFS filesystem using EFS mount helper"
mkdir -p ${mount_point}
echo "${dns_name}:/  ${mount_point}    efs       tls,defaults,noatime,_netdev      0      0"  >> /etc/fstab
sleep 60
while (true)
do
    mount ${mount_point}
    if [ $? -eq 0 ]; then break; fi
    echo "ERROR mount EFS, will try again in 10 seconds..."
    sleep 10
done

echo "========== Configure Apache Web server"
cd /var/www
mv html html.orig
ln -s ${mount_point}/var_www_html html
systemctl start httpd
systemctl enable httpd

echo "========== Configure SSH to connect to DR web server"
echo "${dr_ssh_key}" > /home/ec2-user/.ssh/id_rsa_ws_dr
cat > /home/ec2-user/.ssh/config <<EOF
Host ws_dr
        Hostname ${dr_private_ip}
        User ec2-user
        IdentityFile /home/ec2-user/.ssh/id_rsa_ws_dr
        StrictHostKeyChecking no
EOF
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa_ws_dr /home/ec2-user/.ssh/config
chmod 600               /home/ec2-user/.ssh/id_rsa_ws_dr /home/ec2-user/.ssh/config

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot