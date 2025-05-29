#!/bin/bash

exec 1> /var/log/cloud-init-mariadb.log 2>&1

echo "Starting MariaDB cloud-init script..."

# ----- Hostname Configuration -----
echo "Setting hostname..."
hostnamectl set-hostname mariadb${db_nb}
# Ensure hostname is preserved
sed -i 's/preserve_hostname: false/preserve_hostname: true/' /etc/cloud/cloud.cfg
echo "Hostname set to mariadb${db_nb} and preserved."

# ----- Install MariaDB Server -----
echo "Installing MariaDB server..."
MAX_RETRIES=5
RETRY_COUNT=0
until yum install -y mariadb-server
do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "Failed to install mariadb-server after $MAX_RETRIES attempts."
    exit 1
  fi
  echo "Retrying MariaDB installation (attempt $RETRY_COUNT)..."
  sleep 5
done
echo "MariaDB server installed successfully."

# ----- EBS Volume Mounting -----
echo "Configuring EBS volume /dev/sdf for /var/lib/mysql..."
DEVICE_NAME="/dev/sdf"
MOUNT_POINT="/var/lib/mysql"

# Stop MariaDB if it's running to prevent issues with the data directory
if systemctl is-active --quiet mariadb; then
  echo "Stopping MariaDB service before mounting..."
  systemctl stop mariadb
fi

# Check if the device has a filesystem
if ! blkid -s TYPE -o value ${DEVICE_NAME}; then
  echo "No filesystem found on ${DEVICE_NAME}. Creating XFS filesystem..."
  mkfs.xfs -f ${DEVICE_NAME}
  echo "XFS filesystem created on ${DEVICE_NAME}."
else
  echo "Filesystem already exists on ${DEVICE_NAME}."
fi

# Create mount point directory if it doesn't exist
if [ ! -d "${MOUNT_POINT}" ]; then
  echo "Creating mount point ${MOUNT_POINT}..."
  mkdir -p ${MOUNT_POINT}
fi

# Add to /etc/fstab for persistent mount
if ! grep -q "${DEVICE_NAME} ${MOUNT_POINT}" /etc/fstab; then
  echo "Adding ${DEVICE_NAME} to /etc/fstab..."
  echo "${DEVICE_NAME} ${MOUNT_POINT} xfs defaults,nofail 0 2" >> /etc/fstab
else
  echo "${DEVICE_NAME} already in /etc/fstab."
fi

# Mount the volume
echo "Mounting ${DEVICE_NAME} to ${MOUNT_POINT}..."
mount ${MOUNT_POINT}
if [ $? -ne 0 ]; then
    echo "Failed to mount ${DEVICE_NAME} to ${MOUNT_POINT}. Trying again after a delay."
    sleep 10
    mount ${MOUNT_POINT}
    if [ $? -ne 0 ]; then
        echo "Critical: Failed to mount ${DEVICE_NAME} to ${MOUNT_POINT} after retry. Exiting."
        exit 1
    fi
fi
echo "${DEVICE_NAME} mounted to ${MOUNT_POINT}."

# Change ownership of the mount point
echo "Changing ownership of ${MOUNT_POINT} to mysql:mysql..."
chown mysql:mysql ${MOUNT_POINT}
chmod 700 ${MOUNT_POINT} # Ensure correct permissions for MariaDB
echo "Ownership of ${MOUNT_POINT} set."

# ----- Start and Enable MariaDB -----
echo "Starting and enabling MariaDB service..."
systemctl start mariadb
if [ $? -ne 0 ]; then
    echo "Failed to start MariaDB. Checking journal..."
    journalctl -xe
    # Attempt to initialize data directory if needed, though systemd service usually handles this.
    # if [ ! -d "${MOUNT_POINT}/mysql" ]; then
    #    echo "MariaDB data directory not found after mount. Initializing..."
    #    mysql_install_db --user=mysql --datadir=${MOUNT_POINT}
    #    systemctl start mariadb
    # fi
    # if systemctl is-active --quiet mariadb; then
    #    echo "MariaDB started successfully after manual intervention."
    # else
    #    echo "Critical: MariaDB failed to start even after intervention. Exiting."
    #    exit 1
    # fi
    echo "Critical: MariaDB failed to start. Exiting."
    exit 1
fi
systemctl enable mariadb
echo "MariaDB service started and enabled."

# ----- Basic MariaDB Configuration for Replication -----
echo "Configuring MariaDB for replication..."
MARIA_CONF_DIR="/etc/my.cnf.d"
REPL_CONF_FILE="${MARIA_CONF_DIR}/master-master.cnf"

mkdir -p ${MARIA_CONF_DIR}

cat << EOF > ${REPL_CONF_FILE}
[mysqld]
server_id=${db_nb}
log-bin=mysql-bin
binlog_format=ROW
auto_increment_increment=2
auto_increment_offset=${db_nb}
bind-address=0.0.0.0
# Recommended for InnoDB and replication
default_storage_engine=InnoDB
innodb_flush_log_at_trx_commit=1
sync_binlog=1
# GTID for easier failover (optional but good practice)
# gtid_strict_mode=ON
# gtid_domain_id=${db_nb} # Use db_nb or a cluster_id if available
EOF
echo "MariaDB replication configuration written to ${REPL_CONF_FILE}."

# ----- Secure MariaDB Installation -----
echo "Securing MariaDB installation..."
ROOT_PASSWORD='StrongPassword123!' # Placeholder - ensure this is changed or managed securely

# It's possible that after `yum install mariadb-server` and `systemctl start mariadb`,
# the root user has no password and can be accessed without one, or uses socket authentication.
# The exact commands might need adjustment based on the default MariaDB setup on Amazon Linux 2.

# Attempt to set root password.
# The first command changes the password for 'root'@'localhost'.
# It's common for MariaDB to also have 'root'@'127.0.0.1' and 'root'@'::1'.
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';"

# Remove anonymous users
mysql -u root -p"${ROOT_PASSWORD}" -e "DELETE FROM mysql.global_priv WHERE User='';"
# Disallow remote root login (ensure root can only connect via localhost)
mysql -u root -p"${ROOT_PASSWORD}" -e "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
# Drop test database
mysql -u root -p"${ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS test;"
mysql -u root -p"${ROOT_PASSWORD}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
# Reload privilege tables
mysql -u root -p"${ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
echo "MariaDB installation secured."

# ----- Create Replication User -----
echo "Creating replication user..."
REPL_USER='repl'
REPL_PASSWORD='ReplicationPassword123!' # Placeholder

mysql -u root -p"${ROOT_PASSWORD}" -e "CREATE USER '${REPL_USER}'@'%' IDENTIFIED BY '${REPL_PASSWORD}';"
mysql -u root -p"${ROOT_PASSWORD}" -e "GRANT REPLICATION SLAVE ON *.* TO '${REPL_USER}'@'%';"
mysql -u root -p"${ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
echo "Replication user '${REPL_USER}' created."

# ----- Restart MariaDB -----
echo "Restarting MariaDB to apply all changes..."
systemctl restart mariadb
if [ $? -ne 0 ]; then
    echo "Failed to restart MariaDB after final configuration. Checking journal..."
    journalctl -xe
    echo "Critical: MariaDB failed to restart. Please check logs. Exiting."
    exit 1
fi
echo "MariaDB restarted successfully."

echo "MariaDB cloud-init script finished successfully."
exit 0
