# Cloud-Init Script Template for EC2 MySQL Client Instance

## Purpose of this Directory

This directory (`cloud_init/`) stores a **user data script template** (`cloud_init_al2_TEMPLATE.sh`). This template is designed to be processed by Terraform to generate a cloud-init script for an Amazon Linux 2 EC2 instance. The primary purpose of the generated script is to automate the installation and configuration of MySQL client tools on the EC2 instance, enabling it to connect to the AWS RDS for MySQL database provisioned by the parent Terraform project (`11_AWS_demo_VPC_RDS_mysql/`).

The parent project also includes logic to copy additional helper scripts (`scripts/latency.py`, `scripts/nmap.sh`) to the EC2 instance using `file` and `remote-exec` provisioners, which are separate from this cloud-init process.

## Script Description

This directory contains the following cloud-init script template:

*   **`cloud_init_al2_TEMPLATE.sh`**:
    *   **Type:** Shell script template.
    *   **Target OS:** Designed for Amazon Linux 2 EC2 instances.
    *   **Processing by Terraform:** This script is **not used directly** as static user data. Instead, it is processed by Terraform's `templatefile` function within the parent project's configuration (e.g., in the `07_instance_linux_al2.tf` file).
    *   **Dynamic Values (Injected by Terraform):** The `templatefile` function injects dynamic values into placeholders within this script. These values are typically derived from the AWS RDS for MySQL instance created by Terraform, such as:
        *   `rds_endpoint_address`: The DNS endpoint (hostname) of the RDS MySQL instance.
        *   `rds_db_port`: The port number the RDS MySQL instance is listening on (default 3306).
        *   `rds_db_user`: The master username for the RDS MySQL instance (e.g., 'admin').
        *   `rds_db_password`: The master password for the RDS MySQL instance. (Note: Passing passwords directly like this should be handled with care; for production, consider alternatives.)
        *   `rds_db_name`: The name of the database created on the RDS instance.
        *   `aws_region`: The AWS region.
    *   **Actions Performed by the Rendered Script:** Once Terraform processes the template and injects the actual values, the resulting cloud-init script executed on the EC2 instance will typically perform the following actions:
        1.  **System Updates:** May include initial system updates (`yum update -y`).
        2.  **Install MySQL Client Tools:** Installs the MySQL command-line client (e.g., `mysql` or `mysql-community-client` depending on the specific package available in AL2 repositories).
        3.  **Helper Script/Configuration (Potentially):**
            *   It might create a basic `.my.cnf` configuration file in the `ec2-user`'s home directory to store some connection defaults (like host, user, port), though often the password is not stored here for security unless permissions are strictly controlled.
            *   It could set environment variables (e.g., `MYSQL_HOST`, `MYSQL_USER`) for use by other scripts or applications, although this is less common for direct `mysql` client usage.
            *   The parent project copies separate helper scripts (`01_create_mysql_table.sh`, `02_insert_records.sh`, etc. if they were part of the `scripts/` dir for MySQL) which would then use the installed `mysql` client and the connection parameters. This cloud-init script primarily ensures the client tool itself is available.
        4.  **Install Other Utilities:** May also install common utility packages like `zsh`, `nmap`, `telnet`, `jq`.

## Usage by Terraform (`templatefile` function)

The Terraform configuration in the parent directory (e.g., in `07_instance_linux_al2.tf`) uses the `templatefile` function to render this script.

**Mechanism:**

1.  **Template Rendering:**
    *   The `aws_instance` resource definition for the EC2 client will use the `templatefile` function to generate the user data.
    *   The first argument to `templatefile` is the path to this template script (`${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh`).
    *   The second argument is a map of variables to be injected into the template. For example:
        ```terraform
        // In 07_instance_linux_al2.tf or similar
        resource "aws_instance" "al2_mysql_client" {
          // ... other configurations ...
          ami           = var.ami_id_al2 // Example
          instance_type = var.al2_inst_type
          key_name      = var.al2_ssh_key_name

          user_data = templatefile("${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh", {
            rds_endpoint_address = aws_db_instance.mysql_instance.address // Or .endpoint
            rds_db_port          = aws_db_instance.mysql_instance.port
            rds_db_user          = var.mysql_user
            rds_db_password      = random_password.mysql_master_password.result
            rds_db_name          = var.mysql_db_name
            aws_region           = var.aws_region
          })
        }
        ```
2.  **Passing as User Data:** The rendered script content (with placeholders replaced by actual values from the RDS instance and variables) is then passed to the `user_data` argument of the `aws_instance` resource.

When the EC2 instance launches, cloud-init executes this dynamically generated script, installing and configuring the MySQL client tools. This makes the instance ready to connect to the specific RDS for MySQL database created by Terraform, often using further scripts copied by `remote-exec` provisioners in the parent project. Logs from this cloud-init process can be found in `/var/log/cloud-init-output.log` on the instance.
