#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Create basic performance test script"
cat <<EOF > /tmp/test.sh
for i in 1 2 3 4 5
do
  echo "20^2^20"| time bc > /dev/null
done
EOF
chmod +x /tmp/test.sh

echo "========== Create a filesystem on the additional EBS volume"
sleep 30
mkfs -t xfs -L ebsvol1 /dev/sdf       # symlink to /dev/nvme1n1 or to /dev/xvdf
echo "LABEL=ebsvol1  /mnt/ebs1    xfs       defaults,noatime,_netdev      0      0"  >> /etc/fstab
mkdir -p /mnt/ebs1
mount /mnt/ebs1
chown ec2-user:ec2-user /mnt/ebs1

echo "========== Install some packages"
yum install zsh nmap -y

echo "========== Install Docker"
amazon-linux-extras install docker -y
systemctl enable docker --now
usermod -a -G docker ec2-user

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot