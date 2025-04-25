#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init2.log
exec 1> /var/log/cloud-init2.log 2>&1

echo "========== Install some packages"
apt-get update
apt-get install nmap zsh -y

echo "========== Install Apache Web server with PHP support"
apt-get install apache2 php libapache2-mod-php -y
rm -f /var/www/html/index.html
cat >/var/www/html/index.php << EOF
<html>
<body>
This web page is served by server <?php echo gethostname(); ?>
</body>
</html>
EOF
systemctl start apache2
systemctl enable apache2

echo "========== Install latest updates"
apt-get upgrade -y

echo "========== Final reboot"
reboot