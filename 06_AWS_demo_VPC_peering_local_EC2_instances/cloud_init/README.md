# Cloud-Init Scripts for EC2 Instances in VPC Peering Setup

## Purpose of this Directory

This directory (`cloud_init/`) stores user data scripts that are executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of the EC2 instances. These instances are provisioned by the parent Terraform project (`06_AWS_demo_VPC_peering_local_EC2_instances/`), which demonstrates VPC peering between two VPCs in the same AWS account and region.

The primary purpose of these scripts is to initialize the EC2 instances in each VPC, installing necessary tools for general administration and, crucially, for testing network connectivity across the established VPC peering connection.

## Script Descriptions

This directory contains cloud-init scripts tailored for different Linux distributions that might be used for the EC2 instances:

*   **`cloud_init_al2.sh`**:
    *   **Target OS:** Amazon Linux 2.
    *   **Purpose:** Configures EC2 instances running Amazon Linux 2.
    *   **Common Actions:**
        *   Performs system updates (`yum update -y`).
        *   Installs common utility packages such as `zsh`, `nmap`, `telnet`.
        *   May install network performance testing tools like `iperf3` to help verify the bandwidth and latency characteristics of the VPC peering connection.
        *   Ensures basic networking tools (like `ping`) are available and that any local firewalls (like `firewalld` or `iptables`, though often permissive by default on new AMIs for intra-VPC traffic) are configured to allow test traffic if specific tests require it.

*   **`cloud_init_ubuntu.sh`**:
    *   **Target OS:** Ubuntu Server.
    *   **Purpose:** Configures EC2 instances running Ubuntu.
    *   **Common Actions:**
        *   Updates package lists and upgrades installed packages (`apt update && apt upgrade -y`).
        *   Installs common utility packages such as `zsh`, `nmap`, `telnet`.
        *   May install network performance testing tools like `iperf3`.
        *   Similar to the AL2 script, ensures basic network testing tools are functional.

## Common Tasks Performed by these Scripts

Regardless of the specific Linux distribution, these scripts generally aim to:

1.  **System Updates:** Ensure the instance has the latest security patches and software updates upon launch.
2.  **Install Common Utilities:** Provide a baseline set of tools for diagnostics and administration (e.g., `nmap` for port scanning, `telnet` for basic TCP port checks, `zsh` as an alternative shell).
3.  **Install Network Testing Tools:**
    *   Equip the instances with tools specifically useful for testing the VPC peering connection. This often includes `iperf3` for measuring network throughput between instances in the peered VPCs.
    *   Ensure that standard tools like `ping` (ICMP) can be used across the peered connection (requires appropriate Security Group and Network ACL configuration in the parent Terraform setup).
4.  **Prepare for Connectivity Tests:** The overall goal is to make it easy to log into these instances and immediately start testing private IP connectivity to instances in the peered VPC.

## Usage by Terraform

The Terraform configuration in the parent directory, specifically in files like `07_instance1.tf` (for the instance in VPC1) and `08_instance2.tf` (for the instance in VPC2), references these cloud-init scripts.

**Mechanism:**

1.  **Script Selection:** The choice of script (`cloud_init_al2.sh` or `cloud_init_ubuntu.sh`) typically depends on the Amazon Machine Image (AMI) selected for the EC2 instances. The `aws_instance` resource definition will use a variable or a local map to determine the appropriate script based on the chosen AMI or a specified OS type.
2.  **Passing as User Data:**
    *   The content of the selected script is read by Terraform using the `file()` function or `templatefile()` function.
    *   This content is then passed to the `user_data` argument of the respective `aws_instance` resource.
    *   For example, in `07_instance1.tf`:
        ```terraform
        resource "aws_instance" "inst1_in_vpc1" {
          // ... other configurations ...
          # Assuming var.ami_id implies an Amazon Linux 2 instance
          user_data = file("${path.module}/cloud_init/cloud_init_al2.sh")
        }
        ```
    *   And in `08_instance2.tf`:
        ```terraform
        resource "aws_instance" "inst2_in_vpc2" {
          // ... other configurations ...
          # Assuming var.ami_id_vpc2 implies an Amazon Linux 2 instance for VPC2
          user_data = file("${path.module}/cloud_init/cloud_init_al2.sh")
        }
        ```
        (If different OS types were used for `inst1` and `inst2`, the script path would change accordingly).

When each EC2 instance launches, the cloud-init service executes the user data script, preparing it for its role in the VPC peering demonstration. The primary outcome is to have instances ready to test private network connectivity (e.g., `ping <private_ip_of_instance_in_other_vpc>`) across the peer link. Logs from the cloud-init process can be found in `/var/log/cloud-init-output.log` on each instance.
