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
This web page is served by server <?php echo trim(shell_exec("hostname -I")); ?>
</body>
</html>
EOF
systemctl start httpd
systemctl enable httpd

# NOT NEEDED AS IPTABLES NOT ENABLED BY DEFAULT
# echo "========== Open port 80/tcp in Linux Firewall"
# /bin/firewall-offline-cmd --add-port=80/tcp

echo "========== Apply latest updates to Linux OS"
yum update -y

echo "========== Final reboot"
reboot