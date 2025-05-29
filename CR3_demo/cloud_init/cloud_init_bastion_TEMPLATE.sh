#!/bin/bash

### Send stdout and stderr to /var/log/cloud-init-bastion.log
exec 1> /var/log/cloud-init-bastion.log 2>&1

echo "========== Starting cloud-init script for bastion host =========="

echo "========== set a meaningful hostname"
hostnamectl set-hostname bastion
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "========== Install some packages"
MAX_RETRIES=5
RETRY_COUNT=0
# Added mariadb package for MariaDB client tools
until yum install -y zsh nmap mariadb amazon-efs-utils
do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "ERROR: Failed to install packages after $MAX_RETRIES attempts."
    # Decide if this is a critical failure. For bastion, essential tools are important.
    exit 1 
  fi
  echo "WARNING: yum install failed, will try again in 10 seconds (attempt $RETRY_COUNT)..."
  sleep 10
done
echo "Packages (zsh, nmap, mariadb, amazon-efs-utils) installed successfully."

echo "========== Mount the EFS filesystem using EFS mount helper"
mkdir -p ${mount_point}
echo "${dns_name}:/  ${mount_point}    efs       tls,defaults,noatime,_netdev      0      0"  >> /etc/fstab
sleep 60 # Keep a delay before first mount attempt after fstab modification
RETRY_COUNT=0 # Reset retry count for mount operation
while (true)
do
    mount ${mount_point}
    if [ $? -eq 0 ]; then 
      echo "EFS mounted successfully at ${mount_point}."
      # Create Apache config directories on EFS immediately after successful mount
      echo "========== Create Apache vhost config directories on EFS =========="
      mkdir -p "${mount_point}/apache_configs/sites-available"
      chown root:root "${mount_point}/apache_configs"
      chown root:root "${mount_point}/apache_configs/sites-available"
      chmod 755 "${mount_point}/apache_configs"
      chmod 755 "${mount_point}/apache_configs/sites-available"
      echo "Apache vhost config directories created successfully on EFS."
      break; 
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then # Using MAX_RETRIES from package installation
        echo "ERROR: Failed to mount EFS at ${mount_point} after $MAX_RETRIES attempts. Depending on bastion's role, this might be critical."
        # For now, not exiting, as bastion might still be usable for SSH.
        break 
    fi
    echo "WARNING: Failed to mount EFS, will try again in 10 seconds (attempt $RETRY_COUNT)..."
    sleep 10
done

# Ownership of the EFS mount point itself.
# This should be done after creating root-owned subdirectories if we want to keep them root-owned.
# The current placement of chown for ${mount_point} to ec2-user might be too broad if we want root to own subdirectories.
# However, root can still create/own directories inside even if the top-level is ec2-user owned.
# For simplicity and to match the original script's intent for the mount point, we'll leave this chown.
# The directories /apache_configs/* will remain root:root as set above.
chown ec2-user:ec2-user ${mount_point}

echo "========== Store web pages on EFS filesystem"
# This step might be vestigial or for a different purpose, keeping as is.
# If this was intended for hosting web pages *from* the bastion, it's unusual.
# Typically, web content is served by web servers, not bastions.
# If it's just a shared EFS directory, then it's fine.
mkdir -p ${mount_point}/var_www_html

# echo "========== Install latest updates"
# yum update -y

# echo "========== Final reboot"
# reboot

echo "========== Cloud-init script for bastion host finished. =========="