# Cloud-Init Scripts for EC2 Instances in Cross-Region VPC Peering Setup

## Purpose of this Directory

This directory (`cloud_init/`) stores user data scripts that are executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of the EC2 instances. These instances are provisioned by the parent Terraform project (`07_AWS_demo_VPC_peering_remote_EC2_instances/`). The parent project demonstrates **cross-region VPC peering**, connecting two VPCs located in different AWS regions.

The primary purpose of these scripts is to initialize the EC2 instances—one in each respective region and VPC—installing necessary tools for general administration and, crucially, for testing network connectivity across the established cross-region VPC peering connection.

## Script Descriptions

This directory contains cloud-init scripts tailored for different Linux distributions that might be used for the EC2 instances in each region:

*   **`cloud_init_al2.sh`**:
    *   **Target OS:** Amazon Linux 2.
    *   **Purpose:** Configures EC2 instances running Amazon Linux 2. This script would be used if an Amazon Linux 2 AMI is chosen for an instance in either Region 1 or Region 2.
    *   **Common Actions:**
        *   Performs system updates (`yum update -y`).
        *   Installs common utility packages such as `zsh`, `nmap`, `telnet`.
        *   May install network performance testing tools like `iperf3` to help verify the bandwidth and latency characteristics of the cross-region VPC peering connection.
        *   Ensures basic networking tools (like `ping`) are available.

*   **`cloud_init_ubuntu.sh`**:
    *   **Target OS:** Ubuntu Server.
    *   **Purpose:** Configures EC2 instances running Ubuntu. This script would be used if an Ubuntu AMI is chosen for an instance in either Region 1 or Region 2.
    *   **Common Actions:**
        *   Updates package lists and upgrades installed packages (`apt update && apt upgrade -y`).
        *   Installs common utility packages such as `zsh`, `nmap`, `telnet`.
        *   May install network performance testing tools like `iperf3`.
        *   Similar to the AL2 script, ensures basic network testing tools are functional.

## Common Tasks Performed by these Scripts

Regardless of the specific Linux distribution, these scripts generally aim to:

1.  **System Updates:** Ensure the instance has the latest security patches and software updates upon launch in its respective region.
2.  **Install Common Utilities:** Provide a baseline set of tools for diagnostics and administration.
3.  **Install Network Testing Tools:** Equip the instances with tools (`iperf3`, `ping`, `traceroute`) useful for testing the cross-region VPC peering connection, helping to measure latency and throughput between instances in the different regional VPCs.
4.  **Prepare for Connectivity Tests:** The overall goal is to enable easy login to these instances to immediately start testing private IP connectivity to the instance in the peered VPC (in the other region).

## Usage by Terraform

The Terraform configuration in the parent directory, particularly in files that define the EC2 instances for each region (e.g., `07_instance1.tf` for the instance in Region 1, and `08_instance2.tf` for the instance in Region 2, or similar naming), references these cloud-init scripts.

**Mechanism:**

1.  **Script Selection:** The choice of script (`cloud_init_al2.sh` or `cloud_init_ubuntu.sh`) for each EC2 instance depends on the Amazon Machine Image (AMI) selected for that instance. The `aws_instance` resource definition within each regional provider block will use a variable or a local map to determine the appropriate script based on the chosen AMI or a specified OS type for that region's instance.
2.  **Passing as User Data:**
    *   The content of the selected script is read by Terraform using the `file()` function or `templatefile()` function.
    *   This content is then passed to the `user_data` argument of the respective `aws_instance` resource.
    *   For example, for an instance in Region 1 (defined using the `aws.r1` provider alias):
        ```terraform
        // In a file like 07_instance1.tf
        resource "aws_instance" "inst1_in_vpc1_region1" {
          provider = aws.r1 // Specifies this instance is in Region 1
          // ... other configurations for instance in Region 1 ...
          # Assuming var.ami_id_region1 implies an Amazon Linux 2 instance
          user_data = file("${path.module}/cloud_init/cloud_init_al2.sh")
        }
        ```
    *   And for an instance in Region 2 (defined using the `aws.r2` provider alias):
        ```terraform
        // In a file like 08_instance2.tf
        resource "aws_instance" "inst2_in_vpc2_region2" {
          provider = aws.r2 // Specifies this instance is in Region 2
          // ... other configurations for instance in Region 2 ...
          # Assuming var.ami_id_region2 implies an Ubuntu instance
          user_data = file("${path.module}/cloud_init/cloud_init_ubuntu.sh")
        }
        ```

When each EC2 instance launches in its respective region, the cloud-init service executes the user data script, preparing it for its role in the cross-region VPC peering demonstration. The primary outcome is to have instances ready to test private network connectivity (e.g., `ping <private_ip_of_instance_in_other_region_vpc>`) across the peer link. Logs from the cloud-init process can be found in `/var/log/cloud-init-output.log` on each instance.
