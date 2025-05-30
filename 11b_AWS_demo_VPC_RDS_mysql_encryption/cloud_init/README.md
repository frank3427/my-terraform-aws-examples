# Cloud-Init Script Template for EC2 MySQL Client (with Encryption Focus)

## Purpose of this Directory

This directory (`cloud_init/`) stores a **user data script template** (`cloud_init_al2_TEMPLATE.sh`). This template is designed to be processed by Terraform to generate a cloud-init script for an Amazon Linux 2 EC2 instance. The primary purpose of the generated script is to automate the installation and configuration of MySQL client tools on the EC2 instance. This enables it to connect securely to the AWS RDS for MySQL database provisioned by the parent Terraform project (`11b_AWS_demo_VPC_RDS_mysql_encryption/`), which emphasizes **encryption in transit** (e.g., by setting `require_secure_transport=ON` in a custom DB parameter group).

The parent project also includes logic to copy additional helper scripts (`scripts/latency.py`, `scripts/nmap.sh`) to the EC2 instance using `file` and `remote-exec` provisioners, which are separate from this cloud-init process.

## Script Description

This directory contains the following cloud-init script template:

*   **`cloud_init_al2_TEMPLATE.sh`**:
    *   **Type:** Shell script template.
    *   **Target OS:** Designed for Amazon Linux 2 EC2 instances.
    *   **Processing by Terraform:** This script is processed by Terraform's `templatefile` function within the parent project's configuration (e.g., in a file like `07_instance_linux_al2.tf`).
    *   **Dynamic Values (Injected by Terraform):** The `templatefile` function injects dynamic values into placeholders within this script, derived from the AWS RDS for MySQL instance. These include:
        *   `rds_endpoint_address`: The DNS endpoint (hostname) of the RDS MySQL instance.
        *   `rds_db_port`: The port number for the RDS MySQL instance (default 3306).
        *   `rds_db_user`: The master username (e.g., 'admin').
        *   `rds_db_password`: The master password.
        *   `rds_db_name`: The database name.
        *   `aws_region`: The AWS region.
    *   **Actions Performed by the Rendered Script:**
        1.  **System Updates:** May perform initial system updates (`yum update -y`).
        2.  **Install MySQL Client Tools:** Installs the MySQL command-line client (e.g., `mysql` or `mysql-community-client` from Amazon Linux repositories).
        3.  **SSL/TLS Configuration for Secure Connection:**
            *   The parent project configures the RDS for MySQL instance to enforce encrypted connections (using `require_secure_transport=ON`).
            *   When connecting to RDS MySQL over SSL/TLS using the default AWS-provided certificates for RDS, the standard system CA certificate bundle available on Amazon Linux 2 is typically sufficient for the MySQL client to validate the server's certificate and establish a secure connection.
            *   Therefore, this script usually **does not need to install custom CA certificates**. The MySQL client, when connecting with SSL options enabled (often default or specified with `--ssl-mode=REQUIRED` or `VERIFY_IDENTITY`), will use the system's CA store.
            *   If, hypothetically, the RDS instance were configured with a custom CA or a self-signed certificate (which is not standard for RDS managed SSL), this script would need to be significantly modified to download that specific CA certificate and configure the MySQL client to trust it. This demo assumes standard RDS SSL.
        4.  **Helper Configuration (Potentially):**
            *   Might create a basic `.my.cnf` in the `ec2-user`'s home directory with connection parameters (host, user, port). It's generally not recommended to store the password directly in `.my.cnf` without strict file permissions.
        5.  **Install Other Utilities:** May also install common utility packages like `zsh`, `nmap`, `telnet`, `jq`.

## Usage by Terraform (`templatefile` function)

The Terraform configuration in the parent directory uses the `templatefile` function to render this script with the specific details of the created RDS instance.

**Mechanism:**

1.  **Template Rendering:**
    *   The `aws_instance` resource definition for the EC2 client uses the `templatefile` function to generate the `user_data`.
    *   The first argument to `templatefile` is the path to this template script (`${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh`).
    *   The second argument is a map of variables that Terraform will make available within the template. For example:
        ```terraform
        // In the EC2 instance resource definition in the parent project
        resource "aws_instance" "al2_mysql_client_encrypted" {
          // ... other configurations ...
          ami           = var.ami_id_al2
          instance_type = var.al2_inst_type
          key_name      = var.al2_ssh_key_name

          user_data = templatefile("${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh", {
            rds_endpoint_address = aws_db_instance.mysql_instance_encrypted.address
            rds_db_port          = aws_db_instance.mysql_instance_encrypted.port
            rds_db_user          = var.mysql_user
            rds_db_password      = random_password.mysql_master_password.result
            rds_db_name          = var.mysql_db_name
            aws_region           = var.aws_region
          })
        }
        ```
2.  **Passing as User Data:** The fully rendered script content (with all placeholders replaced by actual values) is then passed to the `user_data` argument of the `aws_instance` resource.

When the EC2 instance launches, cloud-init executes this dynamically generated script. This ensures the MySQL client tools are installed and the instance is ready to connect securely (over SSL/TLS) to the RDS for MySQL database. Connection attempts from the client would then typically use SSL parameters (e.g., `mysql --ssl-mode=REQUIRED ...` or as per client defaults when server enforces SSL).

Logs from the cloud-init process can be found in `/var/log/cloud-init-output.log` on the instance.
