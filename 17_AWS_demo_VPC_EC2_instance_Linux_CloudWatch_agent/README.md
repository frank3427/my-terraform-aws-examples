# Terraform AWS: EC2 with CloudWatch Agent for Metrics Collection

This Terraform project demonstrates how to provision a Linux EC2 instance (Amazon Linux 2) and configure it to send a comprehensive set of system-level metrics (and potentially logs) to AWS CloudWatch using the **AWS CloudWatch Agent**.

## Purpose

The primary goal is to showcase the use of the official AWS CloudWatch Agent for enhanced monitoring capabilities beyond the default EC2 metrics. The CloudWatch Agent allows for:
*   Collection of system-level metrics from EC2 instances (e.g., memory usage, disk space, CPU utilization at a more granular level, custom application metrics).
*   Collection of logs from EC2 instances.
*   Centralized monitoring and alarming on these detailed metrics and logs within CloudWatch.

This project focuses on the setup and basic metric collection aspects.

## Key Components

1.  **VPC Infrastructure:**
    *   A standard VPC with a public subnet and an Internet Gateway (IGW) to allow the EC2 instance to communicate with AWS services and be accessible via SSH.
2.  **EC2 Instance:**
    *   An Amazon Linux 2 EC2 instance launched in the public subnet.
    *   An Elastic IP (EIP) is associated for a static public IP address.
    *   **Detailed Monitoring Enabled:** The instance is configured with `monitoring = true`, which enables 1-minute frequency for standard EC2 CloudWatch metrics (like CPUUtilization from the hypervisor). The CloudWatch Agent can provide even more detailed CPU metrics from within the OS.
3.  **IAM Role for CloudWatch Agent (`aws_iam_role.demo17_cw_for_ec2`):**
    *   An IAM role is created specifically for the EC2 instance.
    *   **Policy Attachment:** The AWS managed policy `CloudWatchAgentServerPolicy` is attached to this role. This policy grants the necessary permissions for the instance (via the agent) to write metric and log data to CloudWatch, and also to interact with SSM if the agent configuration is fetched from SSM Parameter Store (though not the case in this basic setup).
    *   **Instance Profile:** An `aws_iam_instance_profile` is created and associated with this role, which is then attached to the EC2 instance.
4.  **Cloud-Init Script (`cloud_init_al2.sh`):**
    *   This script is passed to the EC2 instance via `user_data` and runs on initial boot.
    *   **Agent Installation:** It installs the `amazon-cloudwatch-agent` package using `yum`.
    *   **Agent Start-up:** It starts the CloudWatch agent using the command:
        ```bash
        sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s
        ```
        This command typically fetches a default configuration suitable for EC2 and starts the agent.
    *   **Note on Agent Configuration:**
        This project **does not explicitly define or push a custom agent configuration file** (e.g., `config.json`) to the instance. The `amazon-cloudwatch-agent-ctl -m ec2 -s` command, when no specific configuration is provided (e.g., via an S3 path or SSM Parameter Store), often applies a default configuration. This default configuration usually collects a standard set of metrics such as memory usage (`mem_used_percent`), disk usage (`disk_used_percent`), and potentially others.
        For more specific metric collection (e.g., metrics from specific processes, custom application metrics) or log file collection, you would typically:
        1.  Create a custom `config.json` file defining the desired metrics and logs.
        2.  Store this configuration in AWS Systems Manager (SSM) Parameter Store or on the instance itself.
        3.  Modify the agent start-up command to fetch this specific configuration (e.g., `amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:<parameter_name> -s`).
    *   **`stress-ng` Installation (Optional):** The cloud-init script also installs `stress-ng` for optional load generation to observe metric changes.

## Highlights

*   **Official AWS CloudWatch Agent:** Utilizes the recommended agent for comprehensive metric and log collection from EC2 instances.
*   **IAM Role for Secure Permissions (`CloudWatchAgentServerPolicy`):** Demonstrates the best practice for granting necessary permissions to the agent.
*   **EC2 Detailed Monitoring:** Standard 1-minute EC2 metrics are enabled alongside agent metrics.
*   **Agent Startup with Default Configuration:** Shows a basic agent startup. For production, a well-defined custom configuration is crucial.

## Key Configuration Variables

*   `aws_region`: The AWS region for deploying all resources (e.g., "us-east-1").
*   `az`: The Availability Zone for the public subnet and EC2 instance (e.g., "us-east-1a").
*   `cidr_vpc`: CIDR block for the VPC (e.g., "10.130.0.0/16").
*   `cidr_subnet1`: CIDR block for the public subnet (e.g., "10.130.1.0/24").
*   `authorized_ips`: List of IPs/CIDRs for SSH access to the EC2 instance (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `inst1_type`: EC2 instance type (e.g., "t2.micro").
*   `al2_ssh_key_name`: Name of an existing EC2 Key Pair in the specified region for SSH access.

## Usage

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    Review the resources that Terraform will create.
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    Provision the AWS resources.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Verifying Metrics in CloudWatch

After successful deployment (allow a few minutes for the agent to start and send initial metrics):

1.  **Navigate to AWS CloudWatch Console:**
    *   Open the AWS Management Console and go to CloudWatch.
    *   Ensure you are in the same AWS region where you deployed the resources.

2.  **Find Agent-Collected Metrics:**
    *   In the CloudWatch console navigation pane, click on "All metrics".
    *   Metrics collected by the CloudWatch Agent are typically published under the **`CWAgent`** namespace. Click on this namespace.
    *   Inside, you'll find metrics categorized by dimensions such as `InstanceId`, `ImageId`, `InstanceType`, etc. Common metrics include:
        *   `mem_used_percent`
        *   `disk_used_percent` (for various mount points like `/` and `/dev/xvda1`)
        *   CPU metrics (e.g., `cpu_usage_idle`, `cpu_usage_user`) - these are more granular than the default EC2 hypervisor CPU metrics.
    *   If the default configuration includes other plugins (like `procstat` for process metrics), those might appear under different namespaces or with different dimension sets.

3.  **Observe the Metrics:**
    *   Select checkboxes next to desired metrics to graph them.
    *   You should see data points appearing, typically at a 1-minute interval (which is often the default collection interval for the agent).

4.  **Optional: Generate Load with `stress-ng`:**
    *   SSH into your EC2 instance.
    *   Run `stress-ng` to generate CPU or memory load:
        ```bash
        # Example: Stress CPU
        stress-ng --cpu 1 --cpu-load 80 --timeout 300s
        # Example: Stress memory
        stress-ng --vm 1 --vm-bytes 512M --timeout 300s
        ```
    *   Observe the corresponding metrics (e.g., `cpu_usage_idle`, `mem_used_percent`) in CloudWatch. You should see changes reflecting the load.

This setup provides a foundation for robust instance monitoring using the CloudWatch Agent. For advanced use cases, customizing the agent's configuration file (`config.json`) is highly recommended to collect precisely the metrics and logs you need.
