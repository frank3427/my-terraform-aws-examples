# Cloud-Init Script Template for EC2 Oracle Client Instance

## Purpose of this Directory

This directory (`cloud_init/`) stores a **user data script template** (`cloud_init_al2_TEMPLATE.sh`). This template is designed to be processed by Terraform to generate a cloud-init script for an Amazon Linux 2 EC2 instance. The primary purpose of the generated script is to automate the installation and configuration of Oracle client tools on the EC2 instance, enabling it to connect to the AWS RDS for Oracle database provisioned by the parent Terraform project (`10_AWS_demo_VPC_RDS_oracle/`).

## Script Description

This directory contains the following cloud-init script template:

*   **`cloud_init_al2_TEMPLATE.sh`**:
    *   **Type:** Shell script template.
    *   **Target OS:** Designed for Amazon Linux 2 EC2 instances.
    *   **Processing by Terraform:** This script is **not used directly** as static user data. Instead, it is processed by Terraform's `templatefile` function within the parent project's configuration (e.g., in the `07_instance_linux_al2.tf` file).
    *   **Dynamic Values (Injected by Terraform):** The `templatefile` function injects dynamic values into placeholders within this script. These values are typically derived from the AWS RDS for Oracle instance created by Terraform, such as:
        *   `rds_endpoint_address`: The DNS endpoint (hostname) of the RDS Oracle instance.
        *   `rds_db_port`: The port number the RDS Oracle instance is listening on (e.g., 1521).
        *   `rds_db_sid`: The Oracle System ID (SID) of the database.
        *   `rds_db_user`: The master username for the RDS Oracle instance.
        *   `rds_db_password`: The master password for the RDS Oracle instance. (Note: Passing passwords directly like this should be handled with care; for production, consider alternatives like fetching from Secrets Manager within the instance if possible, though for client setup this method is common in demos).
        *   `aws_region`: The AWS region, which might be needed for some client configurations or downloads.
    *   **Actions Performed by the Rendered Script:** Once Terraform processes the template and injects the actual values, the resulting cloud-init script executed on the EC2 instance will typically perform the following actions:
        1.  **System Updates:** May include initial system updates (`yum update -y`).
        2.  **Install Oracle Client Prerequisites:** Install any necessary prerequisite packages (e.g., `unzip`, `libaio`).
        3.  **Download and Install Oracle Instant Client/Tools:**
            *   Download Oracle Instant Client RPMs (Basic, SQL*Plus, SDK, Tools) from a specified location (could be S3 or directly from Oracle if network allows and download links are stable, though often these RPMs are bundled with the project or pre-staged).
            *   Install the downloaded RPMs.
        4.  **Configure Oracle Client Networking:**
            *   Create or modify Oracle client networking files like `tnsnames.ora` and `sqlnet.ora`. The `tnsnames.ora` file would be populated with a TNS entry for the RDS Oracle instance, using the injected endpoint, port, and SID.
            *   For example, a `tnsnames.ora` entry might look like:
                ```
                ${rds_db_sid} =
                  (DESCRIPTION =
                    (ADDRESS = (PROTOCOL = TCP)(HOST = ${rds_endpoint_address})(PORT = ${rds_db_port}))
                    (CONNECT_DATA =
                      (SERVER = DEDICATED)
                      (SERVICE_NAME = ${rds_db_sid})
                    )
                  )
                ```
        5.  **Set Environment Variables:**
            *   Set up necessary environment variables for the Oracle client, such as `ORACLE_HOME`, `LD_LIBRARY_PATH`, and `TNS_ADMIN` (pointing to the directory containing `tnsnames.ora`). These are often set in system-wide profile scripts (e.g., in `/etc/profile.d/`).
        6.  **Install Other Utilities:** May also install common utility packages like `zsh`, `nmap`, `telnet`.

## Usage by Terraform (`templatefile` function)

The Terraform configuration in the parent directory (e.g., in `07_instance_linux_al2.tf`) uses the `templatefile` function to render this script.

**Mechanism:**

1.  **Template Rendering:**
    *   The `aws_instance` resource definition for the EC2 client will use the `templatefile` function to generate the user data.
    *   The first argument to `templatefile` is the path to this template script (`${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh`).
    *   The second argument is a map of variables to be injected into the template. For example:
        ```terraform
        // In 07_instance_linux_al2.tf or similar
        resource "aws_instance" "al2_oracle_client" {
          // ... other configurations ...
          ami           = var.ami_id_al2 // Example
          instance_type = var.al2_inst_type
          key_name      = var.al2_ssh_key_name

          user_data = templatefile("${path.module}/cloud_init/cloud_init_al2_TEMPLATE.sh", {
            rds_endpoint_address = aws_db_instance.oracle_instance.address // Or .endpoint
            rds_db_port          = aws_db_instance.oracle_instance.port
            rds_db_sid           = var.oracle_sid // Or from db_instance if available
            rds_db_user          = var.oracle_user
            rds_db_password      = random_password.oracle_master_password.result // Example
            aws_region           = var.aws_region
          })
        }
        ```
2.  **Passing as User Data:** The rendered script content (with placeholders replaced by actual values from the RDS instance and variables) is then passed to the `user_data` argument of the `aws_instance` resource.

When the EC2 instance launches, cloud-init executes this dynamically generated script, installing and configuring the Oracle client tools to connect to the specific RDS Oracle database instance created by Terraform. Logs from this process can be found in `/var/log/cloud-init-output.log` on the instance. This templating approach makes the cloud-init script for client setup highly adaptable to the dynamically created RDS resources.
