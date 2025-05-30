# Cloud-Init Script Template for EC2 Instance with EFS Mount

## Purpose of this Directory

This directory (`cloud_init/`) stores a **user data script template** (`cloud_init_al_TEMPLATE.sh`). This template is designed to be processed by Terraform to generate a cloud-init script for an EC2 instance. The primary purpose of the generated script is to automate the mounting of an AWS Elastic File System (EFS) onto the EC2 instance at boot time.

This is used by the parent Terraform project (`08_AWS_demo_VPC_EC2_instance_Linux_EFS/`).

## Script Description

This directory contains the following cloud-init script template:

*   **`cloud_init_al_TEMPLATE.sh`**:
    *   **Type:** Shell script template.
    *   **Target OS:** Designed for Amazon Linux EC2 instances (typically Amazon Linux 2 or Amazon Linux 2023).
    *   **Processing by Terraform:** This script is **not used directly** as static user data. Instead, it is processed by Terraform's `templatefile` function within the parent project's configuration (e.g., in the `07_instance_linux.tf` file).
    *   **Dynamic Values (Injected by Terraform):** The `templatefile` function injects dynamic values into placeholders within this script. These values are typically derived from other resources created by Terraform, such as:
        *   `efs_file_system_id`: The ID of the AWS EFS file system to be mounted (e.g., `fs-xxxxxxxxxxxxxxxxx`). Alternatively, the EFS DNS name might be passed.
        *   `efs_mount_point`: The desired local directory path on the EC2 instance where the EFS file system will be mounted (e.g., `/mnt/efs`, typically from `var.efs_mount_point`).
        *   `aws_region`: The AWS region where the EFS and EC2 instance reside, sometimes needed for EFS mount helpers.
    *   **Actions Performed by the Rendered Script:** Once Terraform processes the template and injects the actual values, the resulting cloud-init script executed on the EC2 instance will perform the following actions:
        1.  **System Updates:** May include initial system updates (e.g., `yum update -y`).
        2.  **Install EFS Utilities:** Installs the `amazon-efs-utils` package. This package provides tools that simplify mounting EFS, including an NFS client and mount helpers that leverage IAM authorization or TLS for in-transit encryption if configured.
        3.  **Create Mount Point:** Creates the local directory specified by the `efs_mount_point` variable (e.g., `sudo mkdir -p /mnt/efs`).
        4.  **Mount EFS File System:** Uses the `mount` command with the EFS file system ID (or DNS name) and the local mount point to mount the EFS. It often uses the EFS mount helper (`mount -t efs ...`) for recommended options like TLS.
        5.  **Update `/etc/fstab` (for Persistence):** Adds an entry to the `/etc/fstab` file to ensure that the EFS file system is automatically re-mounted if the instance is rebooted. This entry will use the dynamically provided EFS ID and local mount point.
        6.  **Install Common Packages:** May also install other common utility packages like `zsh`, `nmap`, `telnet`, etc., as often seen in these demo projects.

## Usage by Terraform (`templatefile` function)

The Terraform configuration in the parent directory (e.g., in `07_instance_linux.tf`) uses the `templatefile` function to render this script.

**Mechanism:**

1.  **Template Rendering:**
    *   The `aws_instance` resource definition (or a `data "template_cloudinit_config"` resource) will use the `templatefile` function.
    *   The first argument to `templatefile` is the path to this template script (`${path.module}/cloud_init/cloud_init_al_TEMPLATE.sh`).
    *   The second argument is a map of variables to be injected into the template. For example:
        ```terraform
        // In 07_instance_linux.tf or similar
        data "template_file" "cloud_init_script" { // Or directly in user_data
          template = file("${path.module}/cloud_init/cloud_init_al_TEMPLATE.sh")
          vars = {
            efs_dns_name    = aws_efs_file_system.efs.dns_name // Or aws_efs_file_system.efs.id
            efs_mount_point = var.efs_mount_point
            aws_region      = var.aws_region 
            // Any other variables the template might expect
          }
        }

        resource "aws_instance" "linux_instance_efs_client" {
          // ... other configurations ...
          ami                    = var.ami_id_al2023 // Example
          instance_type          = var.al2023_inst_type
          key_name               = var.al2023_ssh_key_name
          // Pass the rendered script content as user_data
          user_data = data.template_file.cloud_init_script.rendered // Or templatefile(...) directly
        }
        ```
2.  **Passing as User Data:** The rendered script content (with placeholders replaced by actual values) is then passed to the `user_data` argument of the `aws_instance` resource.

When the EC2 instance launches, cloud-init executes this dynamically generated script, ensuring the correct EFS file system is mounted at the specified location. Logs from this process can be found in `/var/log/cloud-init-output.log` on the instance. This templating approach makes the cloud-init script reusable and adaptable to EFS resources created by Terraform.
