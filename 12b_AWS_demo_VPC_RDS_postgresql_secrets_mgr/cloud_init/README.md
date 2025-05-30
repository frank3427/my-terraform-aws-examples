# Cloud-Init Script Template for EC2 PostgreSQL Client (with Secrets Manager Integration)

## Purpose of this Directory

This directory (`cloud_init/`) stores a **user data script template** (`cloud_init_al2_TEMPLATE.sh`). This template is designed to be processed by Terraform to generate a cloud-init script for an Amazon Linux 2 EC2 instance. The primary purpose of the generated script is to automate the installation and configuration of PostgreSQL client tools (specifically `psql`) on the EC2 instance.

A key aspect of this setup is that the parent Terraform project (`12b_AWS_demo_VPC_RDS_postgresql_secrets_mgr/`) configures the RDS for PostgreSQL instance to manage its master user password via **AWS Secrets Manager**. Terraform retrieves this generated password from Secrets Manager, and this cloud-init script template is designed to use that retrieved password to configure the `psql` client for seamless, password-less (from the command line perspective) connections.

## Script Description

This directory contains the following cloud-init script template:

*   **`cloud_init_al2_TEMPLATE.sh`**:
    *   **Type:** Shell script template.
    *   **Target OS:** Designed for Amazon Linux 2 EC2 instances.
    *   **Processing by Terraform:** This script is **not used directly** as static user data. Instead, it is processed by Terraform's `templatefile` function within the parent project's configuration (e.g., in a file like `07_instance_linux_al2.tf`).
    *   **Dynamic Values (Injected by Terraform):** The `templatefile` function injects dynamic values into placeholders within this script. These values are derived from the AWS RDS for PostgreSQL instance and AWS Secrets Manager:
        *   `rds_endpoint_address`: The DNS endpoint (hostname) of the RDS PostgreSQL instance.
        *   `rds_db_port`: The port number the RDS PostgreSQL instance is listening on (default 5432).
        *   `rds_db_user`: The master username for the RDS PostgreSQL instance (e.g., 'adm').
        *   `rds_db_password`: **The master password, retrieved by Terraform from AWS Secrets Manager.**
        *   `rds_db_name`: The name of the database created on the RDS instance.
        *   `aws_region`: The AWS region.
    *   **Actions Performed by the Rendered Script:** Once Terraform processes the template and injects the actual values (including the password from Secrets Manager), the resulting cloud-init script executed on the EC2 instance will typically perform the following actions:
        1.  **System Updates:** May include initial system updates (`yum update -y`).
        2.  **Install PostgreSQL Client Tools:** Installs the PostgreSQL command-line client (`psql`) and related libraries (e.g., via `amazon-linux-extras install postgresql<version>` or `yum install postgresql`).
        3.  **Configure `.pgpass` File:**
            *   The script creates a `.pgpass` file in the `ec2-user`'s home directory (`~ec2-user/.pgpass`).
            *   It populates this file with a line containing the connection parameters in the format `hostname:port:database:username:password`, using the values injected by Terraform (including the password retrieved from Secrets Manager).
            *   It then sets strict permissions (e.g., `chmod 0600`) on the `.pgpass` file, which is required by `psql` for security.
            *   This allows `psql` to connect to the specified database as the specified user without interactively prompting for a password.
        4.  **Install Other Utilities:** May also install common utility packages like `zsh`, `nmap`, `telnet`, `jq`.

## Usage by Terraform (`templatefile` function)

The Terraform configuration in the parent directory uses the `templatefile` function to render this script. The password for the RDS instance is first retrieved using `data "aws_secretsmanager_secret_version"` and `jsondecode`.

**Mechanism:**

1.  **Password Retrieval (Parent Project):**
    ```terraform
    data "aws_secretsmanager_secret" "pg_master_secret" {
      name = "rds!db-${var.pg_cluster_identifier}" // Example: depends on how RDS names the secret
    }

    data "aws_secretsmanager_secret_version" "pg_master_secret_version" {
      secret_id = data.aws_secretsmanager_secret.pg_master_secret.id
    }

    locals {
      db_credentials = jsondecode(data.aws_secretsmanager_secret_version.pg_master_secret_version.secret_string)
      db_password    = local.db_credentials.password
    }
    ```
2.  **Template Rendering:**
    *   The `aws_instance` resource definition for the EC2 client uses the `templatefile` function.
    *   The first argument to `templatefile` is the path to this template script (`${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh`).
    *   The second argument is a map of variables, including `rds_db_password = local.db_password`.
        ```terraform
        // In the EC2 instance resource definition in the parent project
        resource "aws_instance" "al2_postgresql_client" {
          // ... other configurations ...
          user_data = templatefile("${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh", {
            rds_endpoint_address = aws_db_instance.postgresql_instance.address
            rds_db_port          = aws_db_instance.postgresql_instance.port
            rds_db_user          = var.pg_user
            rds_db_password      = local.db_password // Password from Secrets Manager
            rds_db_name          = var.pg_db_name
            aws_region           = var.aws_region
          })
        }
        ```
3.  **Passing as User Data:** The rendered script content is passed to the `user_data` argument of `aws_instance`.

When the EC2 instance launches, cloud-init executes this script. The script configures `psql` to use the credentials (including the master password securely fetched from Secrets Manager by Terraform) stored in the `.pgpass` file, enabling convenient and scripted database access from the EC2 client. Logs from cloud-init are in `/var/log/cloud-init-output.log`.
