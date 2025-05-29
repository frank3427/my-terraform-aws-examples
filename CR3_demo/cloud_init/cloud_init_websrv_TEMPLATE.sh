#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init-websrv.log
exec 1> /var/log/cloud-init-websrv.log 2>&1

echo "========== Starting cloud-init script for webserver ${ws_nb} =========="

# Wait for network and other services to be ready if needed, reducing initial sleep
sleep 15 

echo "========== set a meaningful hostname"
hostnamectl set-hostname webserver${ws_nb}
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "========== Install Apache Web server with PHP support + misc packages"
MAX_RETRIES=5
RETRY_COUNT=0
until yum install -y zsh nmap httpd php amazon-efs-utils
do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "ERROR: Failed to install packages after $MAX_RETRIES attempts."
    exit 1
  fi
  echo "WARNING: yum install failed, will try again in 10 seconds (attempt $RETRY_COUNT)..."
  sleep 10
done
echo "Packages installed successfully."

echo "========== Mount the EFS filesystem using EFS mount helper"
mkdir -p ${mount_point}
# Check if EFS is already mounted to prevent duplicate entries in fstab or mount errors
if ! grep -qs "${dns_name}:/ ${mount_point} efs" /etc/fstab; then
  echo "${dns_name}:/  ${mount_point}    efs       tls,defaults,noatime,_netdev      0      0"  >> /etc/fstab
else
  echo "EFS entry already present in /etc/fstab."
fi

# Retry mounting EFS
RETRY_COUNT=0
until mount ${mount_point}
do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "ERROR: Failed to mount EFS at ${mount_point} after $MAX_RETRIES attempts."
    # Consider what to do if EFS mount fails - exit or continue with reduced functionality?
    # For now, we'll exit as EFS is critical for web content.
    exit 1 # Critical failure
  fi
  echo "WARNING: Failed to mount EFS, will try again in 10 seconds (attempt $RETRY_COUNT)..."
  sleep 10
done
echo "EFS mounted successfully at ${mount_point}."

echo "========== Configure Apache Web server for Vhosts =========="
APACHE_CONF_FILE="/etc/httpd/conf/httpd.conf"
APACHE_LOG_DIR="/var/log/httpd" # Standard for Amazon Linux
APACHE_USER="apache"
APACHE_GROUP="apache"

# Ensure IncludeOptional conf.d/*.conf is present and uncommented (usually default)
# Add IncludeOptional sites-enabled/*.conf if not already present
if ! grep -q "IncludeOptional sites-enabled/\*\.conf" "${APACHE_CONF_FILE}"; then
  echo "Adding 'IncludeOptional sites-enabled/*.conf' to ${APACHE_CONF_FILE}"
  echo -e "\n# Vhost configurations" >> "${APACHE_CONF_FILE}"
  echo "IncludeOptional sites-enabled/*.conf" >> "${APACHE_CONF_FILE}"
else
  echo "'IncludeOptional sites-enabled/*.conf' already present in ${APACHE_CONF_FILE}."
fi

# Create directories for vhost configurations
echo "Creating vhost directories..."
mkdir -p /etc/httpd/sites-available
mkdir -p /etc/httpd/sites-enabled

# Create EFS directory structure for vhost *content* (DocumentRoots)
echo "Creating EFS directory for vhosts: ${mount_point}/var_www_vhosts"
mkdir -p "${mount_point}/var_www_vhosts"
chown "${APACHE_USER}:${APACHE_GROUP}" "${mount_point}/var_www_vhosts"
echo "EFS vhost directory created and permissions set."

# Remove local default vhost configuration - all vhosts will be sourced from EFS
echo "Local default vhost configuration is now managed via EFS."
# The local /etc/httpd/sites-available/000-default.conf is no longer created by this script.
# Any default configuration should be placed in ${mount_point}/apache_configs/sites-available/ on EFS.

# Symlink vhost configurations from EFS
echo "Cleaning existing symlinks in /etc/httpd/sites-enabled/..."
find /etc/httpd/sites-enabled/ -type l -delete

EFS_VHOST_CONFIG_DIR="${mount_point}/apache_configs/sites-available"
echo "Looking for vhost configurations in ${EFS_VHOST_CONFIG_DIR}..."
if [ -d "${EFS_VHOST_CONFIG_DIR}" ]; then
    # Check if SELinux is enforcing and consider httpd_use_nfs if needed
    # if sestatus | grep "SELinux status" | grep -q "enabled"; then
    #   if sestatus | grep "Current mode" | grep -q "enforcing"; then
    #     echo "SELinux is enforcing, ensuring httpd_use_nfs is set..."
    #     # Check current state of httpd_use_nfs
    #     # getsebool httpd_use_nfs
    #     # setsebool -P httpd_use_nfs 1 # Uncomment if needed after testing
    #     # echo "If Apache fails to read EFS configs, 'sudo setsebool -P httpd_use_nfs 1' might be required."
    #   fi
    # fi

    for conf_file in $(find "${EFS_VHOST_CONFIG_DIR}" -maxdepth 1 -type f -name "*.conf"); do
        filename=$(basename "$conf_file")
        echo "Creating symlink for $filename in /etc/httpd/sites-enabled/..."
        ln -s "$conf_file" "/etc/httpd/sites-enabled/$filename"
    done
else
    echo "WARNING: EFS vhost config directory ${EFS_VHOST_CONFIG_DIR} not found. No vhosts will be enabled from EFS."
fi

# Original setup for /var/www/html (symlink to EFS)
# This should be reviewed: if default vhost uses ${mount_point}/var_www_html, 
# the DocumentRoot in httpd.conf (if it points to /var/www/html) might become redundant or conflict.
# Typically, the main DocumentRoot in httpd.conf is for the default server if no vhosts match.
# With vhosts enabled, the default vhost config takes precedence for requests to the default server.
echo "Ensuring /var/www/html symlink to EFS is in place..."
if [ ! -L "/var/www/html" ] || [ "$(readlink /var/www/html)" != "${mount_point}/var_www_html" ]; then
  rm -rf /var/www/html # Remove if it's a directory or incorrect symlink
  ln -s "${mount_point}/var_www_html" /var/www/html
  echo "Symlink /var/www/html created to ${mount_point}/var_www_html."
else
  echo "Symlink /var/www/html already correctly points to EFS."
fi


echo "Starting and enabling httpd service..."
systemctl start httpd
if [ $? -ne 0 ]; then
    echo "ERROR: httpd service failed to start. Checking status..."
    systemctl status httpd --no-pager
    journalctl -xe --no-pager -u httpd
    exit 1 # httpd failed to start, critical for webserver
fi
systemctl enable httpd
echo "Apache (httpd) service configured, started, and enabled."


echo "========== Configure SSH to connect to DR web server"
# Ensure /home/ec2-user/.ssh exists
mkdir -p /home/ec2-user/.ssh
chown ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh

echo "${dr_ssh_key}" > /home/ec2-user/.ssh/id_rsa_ws_dr
cat > /home/ec2-user/.ssh/config <<EOF
Host ws_dr
        Hostname ${dr_private_ip}
        User ec2-user
        IdentityFile /home/ec2-user/.ssh/id_rsa_ws_dr
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null 
EOF
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa_ws_dr /home/ec2-user/.ssh/config
chmod 600               /home/ec2-user/.ssh/id_rsa_ws_dr
chmod 644               /home/ec2-user/.ssh/config # config can be 644 or 600
echo "SSH configuration for DR web server completed."

# yum update -y (can be time-consuming, enable if necessary)
# reboot (usually not needed unless kernel updates, etc.)

echo "========== Cloud-init script for webserver ${ws_nb} finished. =========="
# Final restart of Apache to ensure all configs are loaded, especially after symlinking.
# The previous start might be sufficient, but a restart is safer.
echo "Performing a final restart of httpd to ensure all configurations are applied..."
systemctl restart httpd
if [ $? -ne 0 ]; then
    echo "ERROR: httpd service failed to restart at the end of the script. Checking status..."
    systemctl status httpd --no-pager
    journalctl -xe --no-pager -u httpd
    # Non-critical at this point as it might have started earlier, but log it.
fi
echo "Final httpd restart attempted."