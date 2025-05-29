# Cloud-Init Scripts for Bastion and Web Server Instances (ALB Setup)

## Purpose of this Directory

This directory (`cloud_init/`) stores user data scripts that are executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of EC2 instances within the parent Terraform project (`04_AWS_demo_VPC_ELB_ALB/`). These scripts automate the initial setup and configuration of the bastion host and the web server instances, which are fronted by an Application Load Balancer (ALB).

## Script Descriptions

This directory contains the following cloud-init scripts:

*   **`cloud_init_bastion.sh`**:
    *   **Target Instance(s):** The Bastion Host EC2 instance.
    *   **Purpose:** Configures the bastion host, providing a secure administrative entry point to other resources within the VPC, such as the web servers typically located in private subnets.
    *   **Common Actions:**
        *   System updates (e.g., `yum update -y` or `apt update && apt upgrade -y`, depending on the chosen AMI).
        *   Installation of common networking utilities and diagnostic tools (e.g., `nmap`, `telnet`, `traceroute`, `tcpdump`, `zsh`).
        *   Any specific security configurations or preferred tools for bastion usage.

*   **`cloud_init_websrv.sh`**:
    *   **Target Instance(s):** The Web Server EC2 instances that are registered as targets for the Application Load Balancer (ALB). The parent project (`04_AWS_demo_VPC_ELB_ALB/`) might involve path-based routing, meaning different instances or groups of instances could serve different content based on the URL path.
    *   **Purpose:** Sets up each instance to serve web content as part of the backend pool for the ALB.
    *   **Common Actions:**
        *   System updates.
        *   Installation of a web server software (e.g., Nginx or Apache HTTP Server).
        *   Deployment of a sample web page or application.
            *   If path-based routing is used by the ALB, this script might be generic, or different versions/configurations of this script could be used for different sets of web servers to deploy specific content for different paths (e.g., one set of servers for `/app1`, another for `/app2`).
            *   Often, a simple page displaying the instance's hostname, IP address, or a unique identifier for the content it serves (e.g., "Service for /path1") is deployed to help verify ALB routing.
        *   Ensuring the web server service is started and enabled to run on boot.
        *   Installation of necessary runtime environments (e.g., PHP, Python, Node.js) if serving dynamic content.

## Usage by Terraform

The Terraform configurations in the parent directory, particularly in files such as `07_ec2_instance_bastion.tf` (for the bastion host) and `08_ec2_instances_websrv.tf` (for the web server instances, or within launch templates if an Auto Scaling Group is used), reference these scripts.

**Mechanism:**

1.  **File Selection:** The `aws_instance` resource definition for the bastion host will typically point to `cloud_init_bastion.sh`. The `aws_instance` resource definitions (or launch template) for the web server instances will point to `cloud_init_websrv.sh`.
2.  **Passing as User Data:**
    *   The content of the selected script is read by Terraform, often using the `file()` function or `templatefile()` function (if dynamic content needs to be injected into the script, such as unique identifiers or configuration parameters).
    *   This content is then passed to the `user_data` argument of the `aws_instance` resource (or `aws_launch_template` resource).
    *   For example, in `07_ec2_instance_bastion.tf`:
        ```terraform
        resource "aws_instance" "bastion" {
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_bastion.sh")
        }
        ```
    *   And for web servers (e.g., in `08_ec2_instances_websrv.tf` or a launch template):
        ```terraform
        resource "aws_instance" "websrv" { // Or within a launch template
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_websrv.sh")
        }
        ```

Upon launching, the cloud-init service on each EC2 instance executes the provided user data script, automating its specific role setup. Logs from this process are typically available in `/var/log/cloud-init-output.log` on the instance, which is useful for diagnosing any issues during the initialization phase. Given the ALB context, ensuring the web servers correctly report as healthy to the ALB's target group health checks is a key outcome of the `cloud_init_websrv.sh` script.
