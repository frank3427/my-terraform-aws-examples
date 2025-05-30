# Cloud-Init Script for EC2 Instance (S3 Interaction Demo)

## Purpose of this Directory

This directory (`cloud_init/`) stores the user data script (`cloud_init_al2.sh`) that is executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of the EC2 instance within the parent Terraform project (`05_AWS_demo_VPC_S3_EC2_instance_Linux/`).

The primary purpose of this script is to initialize the Amazon Linux 2 EC2 instance, preparing it for general use and, more specifically, for interacting with AWS S3 services, often through a VPC Gateway Endpoint as configured by the parent project.

## Script Description

This directory contains the following cloud-init script:

*   **`cloud_init_al2.sh`**:
    *   **Target OS:** Amazon Linux 2.
    *   **Purpose:** Configures the EC2 instance with necessary tools and updates. While the instance's ability to interact with S3 is primarily granted by its IAM Instance Profile (defined in the parent Terraform configuration), this script ensures the instance has appropriate tools and is up-to-date.
    *   **Common Actions Performed:**
        *   **System Updates:** Runs `yum update -y` to update all system packages to their latest versions.
        *   **Package Installations:** Installs a set of common utility packages, which might include:
            *   `zsh`: An alternative shell.
            *   `nmap`: For network exploration and security auditing.
            *   `telnet`: For basic port connectivity testing.
            *   `jq`: A command-line JSON processor.
            *   `tree`: To display directory structures.
            *   `git`: Version control system.
        *   **AWS CLI:** Amazon Linux 2 typically comes with the AWS CLI pre-installed. This script might include commands to ensure it's present or update it if a specific version were needed, though often it relies on the AMI's provided version.
        *   **Example File/Directory Setup (Potentially):** Depending on the tests intended for the parent project, this script might create sample files or directories that could then be used with `aws s3 cp` commands to test S3 upload/download functionality from the instance.
        *   **Mountpoint for S3 (Potentially):** If the parent project aimed to demonstrate Mounting S3 buckets as local filesystems, this script could include steps to install and configure `mountpoint-s3`. (This would be a more advanced use case).

## Usage by Terraform

The Terraform configuration in the parent directory, specifically within the `07_instance.tf` file (or a similarly named file defining the EC2 instance), references this `cloud_init_al2.sh` script.

**Mechanism:**

1.  **File Referencing:** The `aws_instance` resource definition for the EC2 instance points to `cloud_init_al2.sh`.
2.  **Passing as User Data:**
    *   The content of the `cloud_init_al2.sh` script is read by Terraform, typically using the `file()` function:
        ```terraform
        resource "aws_instance" "demo5_inst1" {
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_al2.sh")
          // Or potentially templatefile() if variables were injected
        }
        ```
    *   This script content is then passed as the `user_data` argument when the EC2 instance is launched.

When the EC2 instance boots for the first time, the cloud-init service on the instance executes this script. This automates the initial software configuration, making the instance ready for use and for testing S3 connectivity as intended by the parent project (e.g., using `aws s3 ls`, `aws s3 cp` commands as demonstrated in the parent project's output or testing section).

The output of the cloud-init process can be found in `/var/log/cloud-init-output.log` on the instance, which is useful for troubleshooting any issues during the initialization phase.
