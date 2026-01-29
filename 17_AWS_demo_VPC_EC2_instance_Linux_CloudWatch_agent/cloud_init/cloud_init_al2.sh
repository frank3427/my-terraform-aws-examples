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

# Create CloudWatch agent configuration with swap metrics
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "swap": {
        "measurement": [
          "swap_used_percent",
          "swap_free",
          "swap_used"
        ]
      },
      "processes": {
        "measurement": [
          "running",
          "sleeping",
          "dead"
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent with custom configuration
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot