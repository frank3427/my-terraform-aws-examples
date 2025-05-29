# Terraform AWS: VPC Flow Logs for ENI, Custom Metrics, and SNS Alerts

This Terraform project demonstrates a comprehensive monitoring setup by:
1.  Enabling **VPC Flow Logs for a specific Elastic Network Interface (ENI)** (in this case, the primary ENI of a bastion host EC2 instance).
2.  Storing these flow logs in a dedicated **CloudWatch Log Group**.
3.  Creating a **CloudWatch Log Metric Filter** to extract custom metrics from the flow log data (specifically, to count rejected SSH attempts).
4.  Setting up a **CloudWatch Alarm** that monitors this custom metric.
5.  Sending notifications to an **SNS Topic** (and subsequently to an email subscriber) when the alarm state is breached.

## Purpose

The primary goal of this project is to illustrate an end-to-end solution for monitoring network traffic patterns for a specific network interface, deriving actionable insights, and alerting on suspicious or unwanted activity. This example focuses on detecting and alerting on repeated failed (rejected) SSH attempts to a bastion host, but the pattern can be adapted for various other use cases.

This project showcases:
*   Targeted network monitoring using ENI-specific VPC Flow Logs.
*   The power of CloudWatch Log Metric Filters to turn log data into quantifiable metrics.
*   Proactive alerting using CloudWatch Alarms based on custom metrics.
*   Notification delivery via SNS for timely operational awareness.

## Key Components

1.  **Base Infrastructure:**
    *   A **VPC** with public and private subnets.
    *   A **Bastion Host EC2 instance** launched in the public subnet. The primary network interface of this bastion host is the specific ENI being monitored.
    *   (Other resources like web servers and a Network Load Balancer are part of the broader environment but are not the direct focus of the flow log monitoring setup itself).
2.  **VPC Flow Log for Bastion's ENI (`10_flow_logs_ENI_bastion.tf`):**
    *   **IAM Role (`aws_iam_role.demo39_flow_log`):** An IAM role is created with permissions that allow the VPC Flow Logs service to publish logs to CloudWatch Logs (e.g., using the `vpc-flow-logs.amazonaws.com` service principal and a policy granting `logs:CreateLogStream`, `logs:PutLogEvents`, etc.).
    *   **CloudWatch Log Group (`aws_cloudwatch_log_group.demo39_flow_log_eni`):** A dedicated log group (e.g., `/aws/eni-flow-logs/bastion-ssh-attempts` or similar, based on `local.flow_log_name`) is created to store the flow logs specifically from the bastion's ENI.
    *   **Flow Log Resource (`aws_flow_log.demo39_bastion_eni`):**
        *   Configured to capture `ALL` traffic (accepted and rejected).
        *   `traffic_type = "ALL"`
        *   **`eni_id`**: Crucially, this is set to the `primary_network_interface_id` of the bastion host EC2 instance, ensuring logs are captured only for this specific interface.
        *   Logs are delivered to the `aws_cloudwatch_log_group.demo39_flow_log_eni`.
        *   Uses the `aws_iam_role.demo39_flow_log.arn` for permissions.
3.  **SNS Notification Setup (`11_sns_topic_email.tf`):**
    *   **SNS Topic (`aws_sns_topic.demo39_alarm_topic`):** An SNS topic is created to serve as the notification channel for alarms.
    *   **Email Subscription (`aws_sns_topic_subscription.demo39_email_target`):**
        *   Subscribes an email address (provided by `var.sns_email`) to the SNS topic.
        *   **Important:** AWS will send a confirmation email to this address. The user must click the link in this email to confirm the subscription before notifications can be received.
4.  **CloudWatch Metric and Alarm from Flow Logs (`12_cloudwatch_metric_and_alarm.tf`):**
    *   **Log Metric Filter (`aws_cloudwatch_log_metric_filter.demo39_rejected_ssh_filter`):**
        *   Associated with the `aws_cloudwatch_log_group.demo39_flow_log_eni`.
        *   **`filter_pattern`:** Designed to match flow log entries that indicate **rejected TCP traffic to port 22** on the monitored ENI. A typical pattern might look for fields representing the ENI ID, destination port 22, TCP protocol, and a "REJECT" action. Example (conceptual, actual pattern depends on log format): `[version, account, eniId, srcaddr, dstaddr, srcport, dstport=22, protocol=6, packets, bytes, start, end, action="REJECT", logstatus]`
        *   **`metric_transformation`:** When a log entry matches the pattern, this configuration transforms it into a custom CloudWatch metric.
            *   **Namespace:** `var.cw_metric_namespace` (e.g., "VPCFlowLogsENI")
            *   **Name:** `var.cw_metric_name` (e.g., "RejectedSSHAttempts")
            *   **Value:** `1` (to count each occurrence).
    *   **CloudWatch Alarm (`aws_cloudwatch_metric_alarm.demo39_rejected_ssh_alarm`):**
        *   Monitors the custom metric created by the log metric filter.
        *   **Threshold:** Triggers if the metric exceeds a defined threshold (e.g., `evaluation_periods = 1`, `threshold = 3` meaning more than 3 rejected SSH attempts within the `period` of, say, 300 seconds / 5 minutes).
        *   **Statistic:** `Sum` or `SampleCount`.
        *   **Actions:** When the alarm state is breached (goes into `ALARM` state), it sends a notification to the configured SNS topic (`aws_sns_topic.demo39_alarm_topic.arn`).

## Workflow (Flow Log -> Metric -> Alarm -> SNS)

1.  Network traffic to/from the bastion host's primary ENI occurs.
2.  **VPC Flow Logs** captures this traffic metadata and publishes it to the `/aws/eni-flow-logs/bastion-ssh-attempts` CloudWatch Log Group.
3.  The **CloudWatch Log Metric Filter** continuously scans these logs. If a log entry matches the pattern for a rejected SSH attempt (TCP port 22, REJECT action, specific ENI), the filter increments the custom `RejectedSSHAttempts` metric in the `VPCFlowLogsENI` namespace.
4.  The **CloudWatch Alarm** monitors this `RejectedSSHAttempts` metric.
5.  If the sum of rejected SSH attempts exceeds the defined threshold (e.g., >3 within 5 minutes), the alarm transitions to the `ALARM` state.
6.  Upon entering the `ALARM` state, the alarm publishes a message to the configured **SNS Topic**.
7.  The SNS topic then forwards this message to all its subscribers, including the email address provided in `var.sns_email` (if confirmed).

## Highlights

*   **ENI-Specific Flow Logs:** Granular network traffic monitoring for individual network interfaces.
*   **Custom Metrics from Logs:** Powerful capability to extract meaningful metrics from raw log data.
*   **Proactive Alerting:** Automated detection and notification of specific network events or anomalies.
*   **Security Use Case:** Demonstrates a practical security monitoring scenario: detecting and alerting on potential brute-force SSH attacks or misconfigured firewall rules targeting the bastion host.

## Key Configuration Variables

*   `aws_region`: The AWS region for deployment.
*   `az_list`: List of Availability Zones.
*   `cidr_vpc`, `cidrs_subnet_public`, `cidrs_subnet_private`: CIDR blocks for VPC and subnets.
*   `authorized_ips`: IPs/CIDRs for SSH access to the bastion.
*   `inst_type_bastion`: Instance type for the bastion host.
*   `al2_ssh_key_name`: SSH key name for the bastion.
*   **`sns_email`**: The email address for receiving SNS alarm notifications. **Crucial for testing.**
*   **`cw_metric_namespace`**: Namespace for the custom CloudWatch metric (e.g., "VPCFlowLogsENI").
*   **`cw_metric_name`**: Name for the custom CloudWatch metric (e.g., "RejectedSSHAttempts").
*   Variables for alarm threshold, period, evaluation periods.

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

4.  **Confirm SNS Subscription:**
    *   After applying, an email will be sent to the address specified in `var.sns_email`.
    *   You **must click the confirmation link** in this email to activate the SNS subscription and receive alarm notifications.

## Verification

After successful deployment and SNS subscription confirmation:

1.  **Check CloudWatch Log Group:**
    *   Navigate to CloudWatch > Log groups.
    *   Find the log group (e.g., `/aws/eni-flow-logs/bastion-ssh-attempts`).
    *   After some time and network activity to/from the bastion, you should see flow log data.

2.  **Simulate Failed SSH Attempts:**
    *   From a machine **not authorized** by the bastion's security group (i.e., an IP not in `var.authorized_ips`), attempt to SSH to the bastion host's public IP multiple times (e.g., 4-5 times within a few minutes).
        ```bash
        ssh -i /path/to/some/key.pem ec2-user@<Bastion_Host_Public_IP> 
        # This should be blocked by the security group, resulting in REJECTED traffic.
        ```
    *   These attempts should be rejected by the bastion's security group, and these rejections will be captured by the VPC Flow Logs.

3.  **Check Custom Metric in CloudWatch:**
    *   Navigate to CloudWatch > All metrics.
    *   Look for the custom namespace `var.cw_metric_namespace` (e.g., "VPCFlowLogsENI").
    *   Find the metric `var.cw_metric_name` (e.g., "RejectedSSHAttempts") under the `eniId` dimension corresponding to your bastion's ENI.
    *   You should see the metric count increase based on the failed SSH attempts.

4.  **Check CloudWatch Alarm State:**
    *   Navigate to CloudWatch > Alarms.
    *   Find the alarm named (e.g., `demo39-rejected-ssh-alarm`).
    *   If the simulated failed SSH attempts exceeded the alarm's threshold, the alarm state should change from `OK` to `In alarm`.

5.  **Check SNS Notification:**
    *   If the alarm entered the `In alarm` state, an email notification should be sent to the address specified in `var.sns_email`.

This verification process confirms the entire workflow, from flow log generation to SNS notification, is functioning as expected. Remember that it might take a few minutes for flow logs to propagate, metrics to update, and alarms to trigger.
