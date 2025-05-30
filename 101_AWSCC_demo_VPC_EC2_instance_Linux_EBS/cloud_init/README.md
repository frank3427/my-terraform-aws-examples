# Cloud-Init Scripts for EC2 Instance Initialization (AWSCC Demo)

## Purpose of this Directory

This directory (`cloud_init/`) stores user data scripts that are executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of EC2 instances. These scripts are specifically for the parent Terraform project (`101_AWSCC_demo_VPC_EC2_instance_Linux_EBS/`), which demonstrates using the AWS Cloud Control (`awscc`) provider for provisioning infrastructure, with the traditional `aws` provider used for resources like EC2 instances where `awscc` might have limitations.

The primary purpose of these scripts is to perform initial configuration on the launched EC2 instances, such as preparing an attached EBS volume, updating the system, and installing common utility packages.

## Script Descriptions

This directory contains cloud-init scripts tailored for different Linux distributions that might be used for the EC2 instances:

*   **`cloud_init_al2.sh`**:
    *   **Target OS:** Amazon Linux 2.
    *   **Purpose:** Configures EC2 instances running Amazon Linux 2.
    *   **Common Actions:**
        *   Updates all system packages (`yum update -y`).
        *   Identifies an attached EBS volume (e.g., `/dev/xvdb` or `/dev/sdb`).
        *   Formats the EBS volume with the XFS filesystem if it's not already formatted.
        *   Creates a mount point (e.g., `/data`) and mounts the XFS volume.
        *   Adds an entry to `/etc/fstab` for persistent mounting of the EBS volume.
        *   Installs common utility packages like `zsh`, `nmap`, `telnet`, `jq`, `tree`, `git`.

*   **`cloud_init_ubuntu.sh`**:
    *   **Target OS:** Ubuntu Server.
    *   **Purpose:** Configures EC2 instances running Ubuntu.
    *   **Common Actions:**
        *   Updates package lists and upgrades installed packages (`apt update && apt upgrade -y`).
        *   Identifies an attached EBS volume.
        *   Formats the EBS volume with XFS if not already formatted.
        *   Creates a mount point and mounts the XFS volume.
        *   Adds an entry to `/etc/fstab`.
        *   Installs common utility packages like `zsh`, `nmap`, `telnet`, `jq`, `tree`, `git`.

## Common Tasks Performed by these Scripts

While specific commands differ based on the Linux distribution, these scripts generally aim to:

1.  **EBS Volume Preparation:**
    *   Locate an attached EBS volume intended for data storage (distinct from the root volume).
    *   Format this volume (commonly with XFS for its robustness and performance characteristics).
    *   Create a standard mount point (e.g., `/data`).
    *   Mount the volume to this directory.
    *   Ensure the volume is mounted automatically on subsequent reboots by adding an entry to `/etc/fstab`.
2.  **System Updates:** Apply the latest security patches and software updates to the instance.
3.  **Install Common Utilities:** Provide a baseline set of tools for system administration, diagnostics, and general use.

## Usage by Terraform

The Terraform configuration in the parent directory, particularly in the file that defines the EC2 instance (e.g., `06_instance_linux.tf`), references one of these cloud-init scripts.

**Mechanism:**

1.  **Script Selection:**
    *   The choice between `cloud_init_al2.sh` and `cloud_init_ubuntu.sh` is typically determined by a Terraform variable in the parent project (e.g., `var.linux_os_version` or implicitly based on the chosen `var.ami_id`).
    *   The Terraform configuration uses this variable to select the path to the appropriate script.
2.  **Passing as User Data:**
    *   The content of the selected script is read by Terraform, usually using the `file()` function:
        ```terraform
        // Example from a file like 06_instance_linux.tf
        // Note: The EC2 instance itself is managed by the 'aws' provider in this project
        // as 'awscc' provider doesn't have a direct EC2 instance resource.
        resource "aws_instance" "linux_instance" {
          // ... other configurations ...
          # The user_data might be selected based on a variable
          user_data = file(var.linux_os_version == "al2" ?
                           "${path.module}/cloud_init/cloud_init_al2.sh" :
                           "${path.module}/cloud_init/cloud_init_ubuntu.sh")
          # Or more simply if only one type is primarily supported by the example:
          # user_data = file("${path.module}/cloud_init/cloud_init_al2.sh")
        }
        ```
    *   This script content is then passed as the `user_data` argument when the `aws_instance` resource is launched.

When the EC2 instance boots for the first time, the cloud-init service on the instance executes this script, automating the initial software configuration and EBS volume setup. The output of the cloud-init process can typically be found in `/var/log/cloud-init-output.log` on the instance, which is useful for troubleshooting.
