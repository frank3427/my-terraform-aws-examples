#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== set a meaningful hostname"
hostnamectl set-hostname <HOSTNAME>
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "========== Install and configure Apache Web server with PHP support"
yum -y install httpd php
cat >/var/www/html/index.php << EOF
<html>
<body>
This web page is served by server <?php echo gethostname(); ?>
</body>
</html>
EOF
systemctl start httpd
systemctl enable httpd

# If you want to see clients source IP addresses instead of ALB private IP addresses in HTTP logs
# you need to add the following lines to /etc/httpd/conf/httpd.conf
#
# RemoteIPHeader x-forwarded-for
# RemoteIPTrustedProxy 10.0.0.0/8
# RemoteIPTrustedProxy 172.16.0.0/12
# RemoteIPTrustedProxy 192.168.0.0/16
# LogFormat %a

# NOT NEEDED AS IPTABLES NOT ENABLED BY DEFAULT
# echo "========== Open port 80/tcp in Linux Firewall"
# /bin/firewall-offline-cmd --add-port=80/tcp

echo "========== Apply latest updates to Linux OS"
yum update -y

echo "========== Final reboot"
reboot