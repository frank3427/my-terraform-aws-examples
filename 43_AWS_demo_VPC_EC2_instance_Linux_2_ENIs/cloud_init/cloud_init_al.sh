#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install and configure Apache Web server with PHP support"
yum -y install httpd php
cat >/var/www/html/index.php << EOF
<html>
<body>
This web page is served by server <?php echo gethostname(); ?>
</body>
</html>
EOF
# mkdir -p /var/www/html/mypath
# cp -p /var/www/html/index.php /var/www/html/mypath
systemctl start httpd
systemctl enable httpd

echo "========== Install some packages"
yum install zsh nmap -y

# echo "========== Apply latest updates to Linux OS"
# yum update -y

# echo "========== Final reboot"
# reboot