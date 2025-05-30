# Cloud-Init Scripts for Bastion and Web Server Instances (ALB with DNS/HTTPS)

## Purpose of this Directory

This directory (`cloud_init/`) stores user data scripts that are executed by [cloud-init](https://cloudinit.readthedocs.io/) during the first boot of EC2 instances within the parent Terraform project (`04b_AWS_demo_VPC_ELB_ALB_DNS_HTTPS/`). These scripts automate the initial setup and configuration of the bastion host and the web server instances. The parent project configures an Application Load Balancer (ALB) with custom DNS names and HTTPS listeners.

## Script Descriptions

This directory contains the following cloud-init scripts:

*   **`cloud_init_bastion.sh`**:
    *   **Target Instance(s):** The Bastion Host EC2 instance.
    *   **Purpose:** Configures the bastion host, which provides a secure administrative entry point to other resources within the VPC, such as the web servers located in private subnets.
    *   **Common Actions:**
        *   System updates (e.g., `yum update -y` or `apt update && apt upgrade -y`, depending on the chosen AMI).
        *   Installation of common networking utilities and diagnostic tools (e.g., `nmap`, `telnet`, `traceroute`, `tcpdump`, `zsh`).
        *   Any specific security configurations or preferred tools for bastion usage.

*   **`cloud_init_websrv.sh`**:
    *   **Target Instance(s):** The Web Server EC2 instances that are registered as targets for the Application Load Balancer (ALB).
    *   **Purpose:** Sets up each instance to serve web content. In the context of the parent project where the ALB handles HTTPS termination, these backend web servers typically:
        *   Serve content over **HTTP** (e.g., on port 80). The ALB listener receives HTTPS traffic from clients, decrypts it, and then forwards requests to these backend instances over HTTP.
    *   **Common Actions:**
        *   System updates.
        *   Installation of a web server software (e.g., Nginx or Apache HTTP Server) configured to listen on HTTP.
        *   Deployment of a sample web page or application. This page is served via HTTP by the instance.
        *   Ensuring the web server service is started and enabled to run on boot.
        *   Installation of necessary runtime environments (e.g., PHP, Python, Node.js) if serving dynamic content.

## Usage by Terraform

The Terraform configurations in the parent directory reference these scripts to provide `user_data` for the EC2 instances.

**Mechanism:**

1.  **File Selection:** The `aws_instance` resource definition for the bastion host will typically point to `cloud_init_bastion.sh`. The `aws_instance` resource definitions (or launch template if an Auto Scaling Group is used) for the web server instances will point to `cloud_init_websrv.sh`.
2.  **Passing as User Data:**
    *   The content of the selected script is read by Terraform, often using the `file()` function or `templatefile()` function.
    *   This content is then passed to the `user_data` argument of the `aws_instance` resource (or `aws_launch_template` resource).
    *   For example:
        ```terraform
        // For the bastion host
        resource "aws_instance" "bastion" {
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_bastion.sh")
        }

        // For web servers (or within a launch template)
        resource "aws_instance" "websrv" {
          // ... other configurations ...
          user_data = file("${path.module}/cloud_init/cloud_init_websrv.sh")
        }
        ```

When each EC2 instance launches for the first time, the cloud-init service executes the provided user data script, automating its specific role setup. Logs from this process are typically available in `/var/log/cloud-init-output.log` on the instance. A key outcome for the web servers is that they are correctly serving HTTP content, ready for the ALB to forward decrypted HTTPS traffic to them.
