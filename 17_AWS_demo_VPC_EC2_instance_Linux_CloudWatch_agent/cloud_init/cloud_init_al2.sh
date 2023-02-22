#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

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

echo "========== Install and start CloudWatch agent (IAM role needed)"
yum install amazon-cloudwatch-agent -y
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot