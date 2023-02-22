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

echo "========== Create script to generate load"
amazon-linux-extras install epel -y
yum install stress-ng -y
cat > /home/ec2-user/stress.sh << EOF
stress-ng --vm 15 --vm-bytes 80% --vm-method all --verify -t 60m -v
#stress-ng --vm 10 -c 10 --vm-bytes 80% --vm-method all --verify -t 60m -v
EOF
chmod +x /home/ec2-user/stress.sh
chown ec2-user:ec2-user /home/ec2-user/stress.sh

echo "========== Create script to create CloudWatch metric about memory usage (IAM role needed)"
INSTANCE_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
REGION=`curl http://169.254.169.254/latest/meta-data/placement/region`
cat > /home/ec2-user/cw_memory.sh << EOF
USEDMEMORY=\$(free -m | awk 'NR==2{printf "%.2f\t", \$3*100/\$2 }')
aws cloudwatch put-metric-data --region $REGION --metric-name memory-usage --dimensions Instance=$INSTANCE_ID --namespace "EC2-Mem" --value \$USEDMEMORY
EOF
chmod +x /home/ec2-user/cw_memory.sh
chown ec2-user:ec2-user /home/ec2-user/cw_memory.sh

echo "========== Execute this script every minute using cron"
echo "*/1 * * * * /home/ec2-user/cw_memory.sh" > /tmp/crontab
crontab -u ec2-user /tmp/crontab
rm -f /tmp/crontab

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot