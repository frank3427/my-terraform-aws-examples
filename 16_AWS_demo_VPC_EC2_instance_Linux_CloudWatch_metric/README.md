# Terraform AWS: EC2 Custom CloudWatch Metrics (Memory Usage)

This Terraform project demonstrates how to provision a Linux EC2 instance (Amazon Linux 2) configured to send custom metrics, specifically memory usage percentage, to AWS CloudWatch using the AWS CLI.

## Purpose

The primary goal of this project is to illustrate a common operational task: monitoring system metrics that are not collected by default by AWS CloudWatch for EC2 instances (like memory utilization). By sending custom metrics, you can gain deeper insights into your instance's performance and set up alarms based on these specific metrics.

This project showcases:
*   Granting necessary permissions to an EC2 instance to publish metrics to CloudWatch using an IAM Role.
*   Automating the setup of metric collection and sending scripts on the EC2 instance using cloud-init (`user_data`).
*   Using the AWS CLI (`aws cloudwatch put-metric-data`) to send custom metric data.
*   Optionally generating load on the instance to observe metric changes.

## Key Components

1.  **VPC Infrastructure:**
    *   A standard VPC with a public subnet and an Internet Gateway (IGW) to allow the EC2 instance to communicate with AWS services and be accessible via SSH.
2.  **EC2 Instance:**
    *   An Amazon Linux 2 EC2 instance launched in the public subnet.
    *   An Elastic IP (EIP) is associated for a static public IP address.
3.  **IAM Role for CloudWatch (`aws_iam_role.demo16_cw_for_ec2`):**
    *   An IAM role is created specifically for the EC2 instance.
    *   **Policy Attachment:** The AWS managed policy `CloudWatchAgentServerPolicy` is attached to this role. This policy grants the necessary permissions for the instance to write metric data to CloudWatch (e.g., `cloudwatch:PutMetricData`).
    *   **Instance Profile:** An `aws_iam_instance_profile` is created and associated with this role, which is then attached to the EC2 instance, allowing applications running on the instance to inherit these permissions.
4.  **Cloud-Init Script (`cloud_init_al2.sh`):**
    *   This script is passed to the EC2 instance via `user_data` and runs on initial boot.
    *   **Metric Collection Script (`/home/ec2-user/cw_memory.sh`):**
        *   The cloud-init script creates a shell script named `cw_memory.sh` in the `ec2-user`'s home directory.
        *   This script calculates the current memory usage percentage on the instance using standard Linux commands (like `free` and `awk`).
        *   It then uses the AWS CLI command `aws cloudwatch put-metric-data` to send this calculated memory usage value as a custom metric.
            *   **Namespace:** `EC2-Mem`
            *   **Metric Name:** `memory-usage`
            *   **Dimensions:** Includes the `InstanceID` as a dimension (e.g., `InstanceID=<instance-id-value>`). This allows you to filter and aggregate metrics per instance.
            *   **Unit:** `Percent`
            *   **Value:** The calculated memory usage percentage.
            *   **Region:** The script is configured to send metrics to the region the EC2 instance is running in.
    *   **Cron Job:** The cloud-init script sets up a cron job to execute `cw_memory.sh` every minute, ensuring continuous reporting of the memory usage metric.
    *   **`stress-ng` Installation (Optional):** The cloud-init script also installs `stress-ng`, a utility for generating various types of system load. This is included to optionally stress the instance and observe how the custom memory metric responds in CloudWatch.

## Highlights

*   **Custom Metric via AWS CLI:** Demonstrates a straightforward method to send any custom data point to CloudWatch using `aws cloudwatch put-metric-data`.
*   **IAM Role for Secure Permissions:** Shows the best practice of using IAM roles to grant EC2 instances permissions to other AWS services, avoiding the need to embed credentials on the instance.
*   **Automation with Cloud-Init:** Leverages cloud-init for a fully automated setup of the metric collection script and cron job on instance launch.

## Key Configuration Variables

*   `aws_region`: The AWS region for deploying all resources (e.g., "us-east-1").
*   `az`: The Availability Zone for the public subnet and EC2 instance (e.g., "us-east-1a").
*   `cidr_vpc`: CIDR block for the VPC (e.g., "10.120.0.0/16").
*   `cidr_subnet1`: CIDR block for the public subnet (e.g., "10.120.1.0/24").
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

## Verifying Custom Metrics

After successful deployment (allow a few minutes for the cron job to run and send initial metrics):

1.  **Navigate to AWS CloudWatch Console:**
    *   Open the AWS Management Console and go to CloudWatch.
    *   Ensure you are in the same AWS region where you deployed the resources.

2.  **Find the Custom Metric:**
    *   In the CloudWatch console navigation pane, click on "All metrics".
    *   You should see a custom namespace box labeled **`EC2-Mem`**. Click on it.
    *   Inside this namespace, you will see a dimension category, typically named after the dimension key used in the script (e.g., `InstanceID` or `Instance`). Click on this.
    *   You should then see the metric named **`memory-usage`** listed for the specific instance ID of your EC2 instance.
    *   Select the checkbox next to this metric to graph it.

3.  **Observe the Metric:**
    *   The graph will show the memory usage percentage reported by the EC2 instance. Since the cron job runs every minute, you should see data points appearing at that interval.
    *   The metric will be under the "EC2-Mem" namespace, with a dimension like "InstanceID = <your-instance-id>" (the dimension name in the console might appear as "Instance" if the script used "InstanceID" as the dimension *Name*).

4.  **Optional: Generate Load with `stress-ng`:**
    *   SSH into your EC2 instance:
        ```bash
        ssh -i /path/to/your/ssh-key.pem ec2-user@<EC2_Instance_Public_IP>
        ```
    *   Run `stress-ng` to consume memory. For example, to stress memory with 2 workers using 512MB each (adjust based on your instance type):
        ```bash
        stress-ng --vm 2 --vm-bytes 512M --timeout 300s
        ```
        (This will run for 300 seconds / 5 minutes).
    *   Observe the `memory-usage` metric in CloudWatch. You should see an increase in the reported memory usage as `stress-ng` consumes memory.

This process confirms that your EC2 instance is successfully sending custom memory metrics to CloudWatch, which can then be used for monitoring, dashboarding, and alarming.
