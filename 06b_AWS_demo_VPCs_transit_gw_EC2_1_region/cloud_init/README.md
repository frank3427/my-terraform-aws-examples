# Cloud-Init Script for EC2 Instances in Transit Gateway Setup

## Purpose of this Directory

This directory (`cloud_init/`) stores the user data script (`cloud_init_al2023.sh`) that is executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of the EC2 instances. These instances are provisioned by the parent Terraform project (`06b_AWS_demo_VPCs_transit_gw_EC2_1_region/`), which demonstrates a multi-VPC architecture interconnected by a central AWS Transit Gateway (TGW) within a single AWS region.

The primary purpose of this script is to initialize the EC2 instances located in each of the "spoke" VPCs, installing necessary tools for general administration and for testing network connectivity to instances in other VPCs across the Transit Gateway.

## Script Description

This directory contains the following cloud-init script:

*   **`cloud_init_al2023.sh`**:
    *   **Target OS:** Amazon Linux 2023.
    *   **Purpose:** Configures EC2 instances running Amazon Linux 2023. This same script is typically applied to all EC2 instances launched in the different VPCs that are connected via the Transit Gateway to ensure a consistent baseline.
    *   **Common Actions:**
        *   Performs system updates using `dnf update -y` (Amazon Linux 2023 uses `dnf` as its package manager, which is a successor to `yum`).
        *   Installs common utility packages such as:
            *   `zsh` (Z Shell)
            *   `nmap` (Network scanner)
            *   `telnet` (For basic TCP port connectivity checks)
            *   `traceroute` (For network path diagnostics)
            *   `bind-utils` (Provides DNS lookup utilities like `dig` and `host`)
        *   May install network performance testing tools like `iperf3` to help verify the bandwidth and latency characteristics of the connections made via the Transit Gateway.
        *   Ensures basic networking tools (like `ping`) are available and that any local firewalls (like `firewalld` or `iptables`, though AL2023 uses `nftables` with `firewalld` as a common frontend) are configured to allow test traffic if specific tests require it (Security Groups and Network ACLs are the primary control planes managed by Terraform).

## Common Tasks Performed by the Script

The `cloud_init_al2023.sh` script generally aims to:

1.  **System Updates:** Ensure the instance has the latest security patches and software updates upon launch.
2.  **Install Common Utilities:** Provide a baseline set of tools for diagnostics, administration, and network troubleshooting.
3.  **Install Network Testing Tools:** Equip the instances with tools useful for testing connectivity to instances in other VPCs through the Transit Gateway.
4.  **Prepare for Connectivity Tests:** The overall goal is to make it easy to log into these instances and immediately start testing private IP connectivity to instances in the other VPCs connected by the Transit Gateway.

## Usage by Terraform

The Terraform configuration in the parent directory, particularly in the file responsible for creating the EC2 instances (e.g., `06_instances.tf`), references this `cloud_init_al2023.sh` script.

**Mechanism:**

1.  **Script Application:** The `aws_instance` resource definitions for EC2 instances in each of the spoke VPCs will use this single script.
2.  **Passing as User Data:**
    *   The content of the `cloud_init_al2023.sh` script is read by Terraform using the `file()` function or `templatefile()` function (if any dynamic values needed to be passed, though this script is likely static).
    *   This content is then passed to the `user_data` argument of the respective `aws_instance` resource(s).
    *   For example, in `06_instances.tf` (or similar):
        ```terraform
        resource "aws_instance" "instances_in_vpc_a" {
          count = var.nb_instances_vpc_a // Example if multiple instances
          // ... other configurations for instances in VPC A ...
          user_data = file("${path.module}/cloud_init/cloud_init_al2023.sh")
        }

        resource "aws_instance" "instances_in_vpc_b" {
          count = var.nb_instances_vpc_b // Example if multiple instances
          // ... other configurations for instances in VPC B ...
          user_data = file("${path.module}/cloud_init/cloud_init_al2023.sh")
        }
        // And so on for other VPCs
        ```

When each EC2 instance launches (regardless of which spoke VPC it's in), the cloud-init service executes this user data script. This ensures all instances have a common set of tools and are prepared for their role in the Transit Gateway connected environment. Logs from the cloud-init process can be found in `/var/log/cloud-init-output.log` on each instance.
