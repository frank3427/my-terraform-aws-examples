# Cloud-Init Script for EC2 Instances in Transit Gateway (Shared Services) Setup

## Purpose of this Directory

This directory (`cloud_init/`) stores the user data script (`cloud_init_al2023.sh`) that is executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of the EC2 instances. These instances are provisioned by the parent Terraform project (`06c_AWS_demo_VPCs_transit_gw_EC2_1_region_shared_services/`). This parent project demonstrates a "Shared Services" VPC architecture where multiple spoke VPCs connect to a central Shared Services VPC via an AWS Transit Gateway (TGW), all within a single AWS region.

The primary purpose of this script is to initialize the EC2 instances located in the Shared Services VPC and in each of the "spoke" VPCs with a common baseline configuration. This includes installing necessary tools for general administration and for testing network connectivity according to the routing rules defined by the Transit Gateway (i.e., spokes to shared services, shared services to spokes, but not spoke-to-spoke directly via TGW).

## Script Description

This directory contains the following cloud-init script:

*   **`cloud_init_al2023.sh`**:
    *   **Target OS:** Amazon Linux 2023.
    *   **Purpose:** Configures EC2 instances running Amazon Linux 2023. This same script is applied to all EC2 instances launched, whether they are in the Shared Services VPC or any of the spoke VPCs, to ensure a consistent set of tools and updates.
    *   **Common Actions:**
        *   Performs system updates using `dnf update -y` (as Amazon Linux 2023 uses `dnf`).
        *   Installs common utility packages useful for system administration, network diagnostics, and testing connectivity. These typically include:
            *   `zsh` (Z Shell)
            *   `nmap` (Network scanner for checking open ports)
            *   `telnet` (For basic TCP port connectivity checks)
            *   `traceroute` (For network path diagnostics)
            *   `bind-utils` (Provides DNS lookup utilities like `dig` and `host`)
        *   May install network performance testing tools like `iperf3`, which can be used to test bandwidth and connectivity between instances in spoke VPCs and instances/services in the Shared Services VPC.
        *   Ensures basic networking tools (like `ping`) are available. Security Groups and Network ACLs, managed by Terraform, will primarily control whether ICMP or other test traffic is permitted between specific instances.

## Common Tasks Performed by the Script

The `cloud_init_al2023.sh` script generally aims to:

1.  **System Updates:** Bring the instance to the latest patch level upon launch.
2.  **Install Common Utilities:** Provide a consistent baseline toolkit across all instances (in shared services and spoke VPCs) for ease of administration and troubleshooting.
3.  **Install Network Testing Tools:** Equip instances with tools to verify the specific network paths allowed by the Transit Gateway custom route tables (e.g., connectivity from a spoke to a shared service, but not between spokes).
4.  **Prepare for Connectivity and Service Access Tests:** The overall goal is to simplify logging into these instances and immediately begin testing DNS resolution, network reachability to shared services, and the isolation between spoke VPCs as configured by the parent project.

## Usage by Terraform

The Terraform configuration in the parent directory, particularly in the file responsible for creating the EC2 instances (e.g., `06_instances.tf` or a similar file), references this `cloud_init_al2023.sh` script for all EC2 instances provisioned.

**Mechanism:**

1.  **Uniform Script Application:** The `aws_instance` resource definitions for EC2 instances in the Shared Services VPC and in all spoke VPCs will typically use this single, common script.
2.  **Passing as User Data:**
    *   The content of the `cloud_init_al2023.sh` script is read by Terraform, usually via the `file()` function.
    *   This script content is then passed to the `user_data` argument of all relevant `aws_instance` resource(s).
    *   For example, in `06_instances.tf` (or similar):
        ```terraform
        // Instance in Shared Services VPC
        resource "aws_instance" "instance_in_shared_services_vpc" {
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_al2023.sh") 
        }

        // Instance in a Spoke VPC
        resource "aws_instance" "instance_in_spoke_vpc_a" {
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_al2023.sh") 
        }
        // And so on for instances in other spoke VPCs
        ```

When each EC2 instance launches, the cloud-init service executes this user data script. This ensures all instances, regardless of their VPC, start with a common package set and are ready for their role in the Shared Services architecture demonstration. Logs from the cloud-init process are available in `/var/log/cloud-init-output.log` on each instance.
