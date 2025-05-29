# Cloud-Init Scripts for Bastion and Web Server Instances

## Purpose of this Directory

This directory (`cloud_init/`) stores user data scripts that are executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of EC2 instances within the parent Terraform project (`03_AWS_demo_VPC_ELB_NLB_single_AZ/`). These scripts automate the initial setup and configuration of the bastion host and the web server instances.

## Script Descriptions

This directory contains the following cloud-init scripts:

*   **`cloud_init_bastion.sh`**:
    *   **Target Instance(s):** The Bastion Host EC2 instance.
    *   **Purpose:** Configures the bastion host, which serves as a secure entry point to access other resources within the VPC (like the web servers in private subnets, though in this specific project web servers might also be in public subnets if simplified).
    *   **Common Actions:**
        *   System updates (e.g., `yum update -y` or `apt update && apt upgrade -y`, depending on the chosen AMI).
        *   Installation of common networking utilities and diagnostic tools (e.g., `nmap`, `telnet`, `traceroute`, `tcpdump`).
        *   Installation of shells or preferred tools (e.g., `zsh`).
        *   Potentially, configuration of SSH settings or security hardening measures.

*   **`cloud_init_websrv.sh`**:
    *   **Target Instance(s):** The Web Server EC2 instances that are registered with the Network Load Balancer (NLB).
    *   **Purpose:** Sets up the instances to serve web content.
    *   **Common Actions:**
        *   System updates.
        *   Installation of a web server software (e.g., Nginx or Apache HTTP Server).
        *   Deployment of a sample web page or application. This often includes a simple HTML or PHP page that might display the instance's hostname or IP address to help verify load balancing.
        *   Ensuring the web server service is started and enabled to run on boot.
        *   Installation of necessary runtime environments if serving dynamic content (e.g., PHP, Python, Node.js).

## Usage by Terraform

The Terraform configurations in the parent directory, specifically within files like `07_ec2_instance_bastion.tf` (for the bastion host) and `08_ec2_instances_websrv.tf` (for the web server instances), reference these scripts.

**Mechanism:**

1.  **File Selection:** The `aws_instance` resource definition for the bastion host will point to `cloud_init_bastion.sh`, and the definitions for the web server instances will point to `cloud_init_websrv.sh`.
2.  **Passing as User Data:**
    *   The content of the selected script is typically read by Terraform using the `file()` function or the `templatefile()` function if variables need to be injected into the script (though these examples are often static scripts).
    *   This content is then passed to the `user_data` argument of the `aws_instance` resource.
    *   For example, in `07_ec2_instance_bastion.tf`:
        ```terraform
        resource "aws_instance" "bastion" {
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_bastion.sh")
        }
        ```
    *   And in `08_ec2_instances_websrv.tf` (if using individual instances or within a launch template for an Auto Scaling Group):
        ```terraform
        resource "aws_instance" "websrv" { // Or within a launch template
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_websrv.sh")
        }
        ```

When each EC2 instance launches for the first time, the cloud-init service executes the provided user data script, automating its specific setup. The output of this process can be found in `/var/log/cloud-init-output.log` on the instance, which is essential for troubleshooting any initialization issues.
