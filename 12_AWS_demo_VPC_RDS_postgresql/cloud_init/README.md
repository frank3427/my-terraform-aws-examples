# Cloud-Init Script Template for EC2 PostgreSQL Client Instance

## Purpose of this Directory

This directory (`cloud_init/`) stores a **user data script template** (`cloud_init_al2_TEMPLATE.sh`). This template is designed to be processed by Terraform to generate a cloud-init script for an Amazon Linux 2 EC2 instance. The primary purpose of the generated script is to automate the installation and configuration of PostgreSQL client tools (specifically `psql`) on the EC2 instance. This enables the instance to connect to the AWS RDS for PostgreSQL database provisioned by the parent Terraform project (`12_AWS_demo_VPC_RDS_postgresql/`).

The parent project also includes logic to copy a directory of SQL scripts (`sql_scripts/`) to the EC2 instance using `file` provisioner, which can then be used with the `psql` client set up by this cloud-init script.

## Script Description

This directory contains the following cloud-init script template:

*   **`cloud_init_al2_TEMPLATE.sh`**:
    *   **Type:** Shell script template.
    *   **Target OS:** Designed for Amazon Linux 2 EC2 instances.
    *   **Processing by Terraform:** This script is **not used directly** as static user data. Instead, it is processed by Terraform's `templatefile` function within the parent project's configuration (e.g., in the `07_instance_linux_al2.tf` file).
    *   **Dynamic Values (Injected by Terraform):** The `templatefile` function injects dynamic values into placeholders within this script. These values are typically derived from the AWS RDS for PostgreSQL instance created by Terraform, such as:
        *   `rds_endpoint_address`: The DNS endpoint (hostname) of the RDS PostgreSQL instance.
        *   `rds_db_port`: The port number the RDS PostgreSQL instance is listening on (default 5432).
        *   `rds_db_user`: The master username for the RDS PostgreSQL instance (e.g., 'adm').
        *   `rds_db_password`: The master password for the RDS PostgreSQL instance.
        *   `rds_db_name`: The name of the database created on the RDS instance.
        *   `aws_region`: The AWS region.
    *   **Actions Performed by the Rendered Script:** Once Terraform processes the template and injects the actual values, the resulting cloud-init script executed on the EC2 instance will typically perform the following actions:
        1.  **System Updates:** May include initial system updates (`yum update -y`).
        2.  **Install PostgreSQL Client Tools:** Installs the PostgreSQL command-line client and related libraries. For Amazon Linux 2, this is often done via `amazon-linux-extras install postgresql<version>` (e.g., `amazon-linux-extras install postgresql14`) or `yum install postgresql`.
        3.  **Configure Client for Easy Connection (Potentially):**
            *   **`.pgpass` file:** The script might create a `.pgpass` file in the `ec2-user`'s home directory (`~ec2-user/.pgpass`). This file stores connection parameters (host:port:database:user:password) and allows `psql` to connect without prompting for a password if a matching entry is found. The script would populate this file using the injected RDS details. This is a common way to automate `psql` logins for scripts.
                *Example `.pgpass` entry format: `hostname:port:database:username:password`*
            *   **Environment Variables:** Alternatively, or in addition, it might set environment variables like `PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE`, and `PGPASSWORD`. However, using `PGPASSWORD` is generally less secure than `.pgpass` because the password can be visible in the process list.
        4.  **Install Other Utilities:** May also install common utility packages like `zsh`, `nmap`, `telnet`, `jq`.

## Usage by Terraform (`templatefile` function)

The Terraform configuration in the parent directory (e.g., in `07_instance_linux_al2.tf`) uses the `templatefile` function to render this script.

**Mechanism:**

1.  **Template Rendering:**
    *   The `aws_instance` resource definition for the EC2 client will use the `templatefile` function to generate the `user_data`.
    *   The first argument to `templatefile` is the path to this template script (`${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh`).
    *   The second argument is a map of variables to be injected into the template. For example:
        ```terraform
        // In 07_instance_linux_al2.tf or similar
        resource "aws_instance" "al2_postgresql_client" {
          // ... other configurations ...
          ami           = var.ami_id_al2 // Example
          instance_type = var.al2_inst_type
          key_name      = var.al2_ssh_key_name

          user_data = templatefile("${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh", {
            rds_endpoint_address = aws_db_instance.postgresql_instance.address // Or .endpoint
            rds_db_port          = aws_db_instance.postgresql_instance.port
            rds_db_user          = var.pg_user
            rds_db_password      = random_password.pg_master_password.result
            rds_db_name          = var.pg_db_name
            aws_region           = var.aws_region
          })
        }
        ```
2.  **Passing as User Data:** The rendered script content (with placeholders replaced by actual values from the RDS instance and variables) is then passed to the `user_data` argument of the `aws_instance` resource.

When the EC2 instance launches, cloud-init executes this dynamically generated script, installing and configuring the PostgreSQL client tools (`psql`). This makes the instance ready to connect to the specific RDS for PostgreSQL database created by Terraform, using the provided credentials and potentially leveraging a `.pgpass` file for convenience when running the SQL scripts copied by the parent project. Logs from this cloud-init process can be found in `/var/log/cloud-init-output.log` on the instance.
