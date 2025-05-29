# Terraform AWS: Scalable Web Application with Auto Scaling Group and ALB

This Terraform project demonstrates how to provision a scalable and resilient web application infrastructure on AWS. It utilizes an EC2 Auto Scaling Group (ASG) to manage application instances, fronted by an Application Load Balancer (ALB) for traffic distribution and high availability. The entire setup is within a custom VPC with public and private subnets spread across multiple Availability Zones (AZs).

## Key Features & Concepts

*   **Scalability & High Availability:**
    *   **Auto Scaling Group (ASG):** Automatically adjusts the number of EC2 instances based on demand (though this demo uses fixed desired/min/max settings) and maintains the desired instance count by replacing unhealthy instances.
    *   **Multi-AZ Deployment:** The ALB is deployed across multiple public subnets in different AZs. The ASG launches instances across multiple private subnets in different AZs. This design ensures the application can withstand the failure of a single Availability Zone.
*   **Application Load Balancer (ALB):**
    *   Distributes incoming HTTP traffic across the healthy EC2 instances managed by the ASG.
    *   Integrates with the ASG for health checks and automatic registration/deregistration of instances.
*   **Launch Templates (`aws_launch_template`):**
    *   Defines the configuration for EC2 instances launched by the ASG, including AMI, instance type, key pair, security groups, and user data (for web server setup). This promotes consistency and simplifies updates.
*   **Private Subnets for Application Instances:** EC2 instances running the web application are placed in private subnets, enhancing security by not exposing them directly to the internet. They rely on the ALB for inbound traffic and a NAT Gateway for outbound internet access.
*   **Bastion Host:** Provides a secure, controlled entry point for SSH access to instances within the private subnets.
*   **Instance Refresh:** The ASG is configured with an `instance_refresh` strategy, allowing for rolling updates to instances when the launch template is updated.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   Configured with public and private subnets across multiple Availability Zones (e.g., `var.az_list`).
    *   **Public Subnets:** Used for the Bastion Host and the Application Load Balancer.
    *   **Private Subnets:** Used for the EC2 instances launched by the Auto Scaling Group.
    *   Includes an Internet Gateway (IGW) attached to the VPC.
*   **NAT Gateway:**
    *   Deployed in one of the public subnets with an Elastic IP.
    *   Provides outbound internet connectivity for instances in the private subnets (e.g., for OS updates, accessing external services). Route tables for private subnets are configured to use the NAT Gateway for internet-bound traffic.
*   **Bastion Host:**
    *   An EC2 instance launched in a public subnet.
    *   Allows secure SSH access to other EC2 instances within the VPC, especially those in private subnets.
*   **Application Load Balancer (ALB) (`aws_lb`):**
    *   Public-facing, deployed across the specified public subnets for high availability.
    *   **Listener:** Configured for HTTP on port 80.
    *   **Target Group (`aws_lb_target_group`):** The ASG registers its instances with this target group. The ALB forwards requests to healthy targets in this group.
*   **Launch Template (`aws_launch_template`):**
    *   Defines the template for EC2 instances:
        *   AMI ID (e.g., for Amazon Linux 2 or 2023).
        *   Instance type (e.g., `var.web_inst_type`).
        *   Key pair name (`var.web_ssh_key_name`).
        *   User data script (e.g., to install a web server like Apache or Nginx and deploy a simple test page).
        *   Associated with the Web Server Security Group.
*   **EC2 Auto Scaling Group (ASG) (`aws_autoscaling_group`):**
    *   Uses the defined `aws_launch_template` to launch and manage EC2 instances.
    *   **Capacity:** Configured with desired, minimum, and maximum instance counts (e.g., `desired_capacity = 2`, `min_size = 2`, `max_size = 3`).
    *   **Subnet Association:** Launches instances into the specified private subnets.
    *   **ALB Integration:** Associated with the ALB's target group. The ASG automatically adds instances to the target group, and the ALB performs health checks.
    *   **Instance Refresh:** Configured with settings for rolling updates if the launch template changes (e.g., strategy, min healthy percentage).
*   **Security Groups:**
    *   **ALB Security Group (`demo18-alb-sg`):**
        *   Inbound: Allows HTTP (TCP port 80) from `authorized_ips` (or `0.0.0.0/0` for public web access).
        *   Outbound: Allows HTTP (TCP port 80) to the Web Server Security Group.
    *   **Web Server Security Group (`demo18-web-sg`):**
        *   Used by instances launched by the ASG.
        *   Inbound:
            *   Allows HTTP (TCP port 80) from the VPC's CIDR block (specifically allowing traffic from the ALB).
            *   Allows SSH (TCP port 22) from the Bastion Host's Security Group.
        *   Outbound: Allows all traffic (or specific traffic needed by the application, including to the NAT Gateway).
    *   **Bastion Security Group (`demo18-bastion-sg`):**
        *   Inbound: Allows SSH (TCP port 22) from `authorized_ips`.

## Architecture

```
        [ AWS Cloud - Region: var.aws_region ]
                         |
        +----------------------------------------------------------------------+
        |                                 VPC                                  |
        |                           (var.cidr_vpc)                             |
        |                                                                      |
        |------------------------ Public Subnets (Multi-AZ) -------------------|
        |  +---------------------+      +-----------------------------------+  |
        |  | Bastion Host (EC2)  |      | Application Load Balancer (ALB)   |  |
        |  | (SG: Bastion SG)    |<-----+ (Public, Spans Public Subnets)    |  |
        |  |      EIP            |      | (SG: ALB SG)                      |  |
        |  +---------------------+      +-------------+---------------------+  |
        |           | (SSH via IGW)                   | (HTTP via IGW)         |
        |           |                                 ▼                        |
        |-----------|--------------- Private Subnets (Multi-AZ) ---------------|
        |           | (SSH)          +-----------------------------------+     |
        |           |                | Auto Scaling Group (ASG)          |     |
        |           +--------------->|  - EC2 Instance 1 (Private IP)    |<----+(ALB Target Group)
        |                            |  - EC2 Instance 2 (Private IP)    |     |
        |                            |  (Uses Launch Template)           |     |
        |                            |  (SG: Web Server SG)              |     |
        |                            +------------------+----------------+     |
        |                                               | (Outbound via NAT GW) |
        |  +---------------------+                      |                      |
        |  | NAT Gateway (EIP)   |<---------------------+                      |
        |  | (In one Public Subnet)|                                            |
        |  +---------------------+                                              |
        |                                                                      |
        +----------------------------------+-------------------------------------+
                                           |
                                    [Internet Gateway]
                                           |
                                       (Internet)
```
Users access the web application via the ALB's DNS name. The ALB distributes traffic to healthy EC2 instances managed by the ASG in private subnets. These instances can make outbound connections via the NAT Gateway. Secure SSH access to web instances is via the Bastion Host.

## Key Configuration Variables

*   **General AWS & VPC:** `aws_region`, `az_list` (list of AZs), `cidr_vpc`, `cidrs_subnet_public`, `cidrs_subnet_private`, `authorized_ips`.
*   **Bastion Host:** `bastion_inst_type`, `bastion_ssh_key_name`.
*   **Application (Web Server) Instances:**
    *   `web_inst_type`: Instance type for ASG instances.
    *   `web_ssh_key_name`: SSH key for ASG instances.
    *   `web_user_data_script_path`: Path to user data script for web server setup.
*   **Auto Scaling Group:**
    *   `asg_desired_capacity`, `asg_min_size`, `asg_max_size`.
    *   Launch template parameters (AMI implicitly derived or specified).
*   **Application Load Balancer:**
    *   ALB name, listener configuration (implicitly HTTP/80).

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

## Testing

After successful deployment:

1.  **Find the ALB DNS Name:**
    Obtain the DNS name of the Application Load Balancer from the Terraform outputs (e.g., `alb_dns_name`) or the AWS EC2 console under "Load Balancers".

2.  **Access the Web Application:**
    Open a web browser and navigate to `http://<ALB_DNS_Name>`.
    You should see the test page served by one of the EC2 instances in the Auto Scaling Group. Refreshing the page might hit different instances if multiple are running.

3.  **Testing Scalability (Manual Trigger):**
    *   You can manually change the `desired_capacity` of the ASG (e.g., via the AWS console or by updating Terraform configuration and re-applying) to observe instances being added or removed.
    *   Terminating an instance in the ASG should trigger the ASG to launch a replacement to maintain the desired capacity.

4.  **Testing Instance Refresh (Manual Trigger):**
    *   Update the launch template (e.g., change the user data script or AMI).
    *   Start an instance refresh for the ASG via the AWS console or AWS CLI. Observe as the ASG replaces old instances with new ones based on the updated launch template.

This setup provides a robust foundation for hosting web applications that require scalability and high availability.
