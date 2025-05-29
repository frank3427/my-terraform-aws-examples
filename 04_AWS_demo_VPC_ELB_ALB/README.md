# Terraform AWS VPC with Application Load Balancer (ALB) and Path-Based Routing

This Terraform project provisions a sophisticated AWS environment featuring an Application Load Balancer (ALB) with path-based routing. It includes a new VPC, multiple public and private subnets across different Availability Zones (AZs), a bastion host for secure access, a NAT Gateway for outbound connectivity, and web server instances.

## Key Features

*   **Application Load Balancer (ALB):** A public-facing ALB intelligently distributes incoming HTTP traffic.
*   **Path-Based Routing:** The ALB is configured with rules to route traffic to different backend server groups based on the URL path.
*   **Multi-AZ Deployment:** The ALB and web server instances are deployed across two specified Availability Zones (`var.websrv_az`) for enhanced availability. The bastion host resides in its own specified AZ (`var.bastion_az`).
*   **Single Bastion Host:** Provides a secure SSH entry point to the environment.
*   **Single NAT Gateway:** Facilitates outbound internet access for instances in private subnets.

## AWS Resources Provisioned

This project will create the following AWS resources:

*   **VPC (Virtual Private Cloud):**
    *   A new VPC for network isolation.
    *   **Internet Gateway (IGW):** Attached to the VPC for internet communication.
*   **Public Subnets:**
    *   **Bastion Public Subnet:** A dedicated public subnet in `var.bastion_az` for the Bastion EC2 instance.
    *   **ALB Public Subnets (x2):** Two public subnets in different Availability Zones (from `var.websrv_az`) designated for the Application Load Balancer.
*   **Private Subnets:**
    *   **Web Server Private Subnets (x2):** Two private subnets in the same Availability Zones as the ALB public subnets (from `var.websrv_az`) to host the web server instances.
*   **Bastion EC2 Instance:**
    *   A single Amazon Linux 2 ARM64 instance.
    *   Located in the dedicated bastion public subnet.
    *   Associated with an **Elastic IP (EIP)** for a static public IP.
    *   Allows SSH access from `authorized_ips`.
    *   Uses a dedicated AWS Key Pair.
*   **NAT Gateway:**
    *   A single NAT Gateway with an **Elastic IP (EIP)**.
    *   Located in the **bastion's public subnet**.
    *   Provides outbound internet access for all private subnets (web servers).
*   **Web Server EC2 Instances (x3):**
    *   Three Amazon Linux 2 ARM64 instances.
    *   Distributed across the two private subnets (e.g., two instances in the first private subnet, one in the second).
    *   Run a simple web service (configured via cloud-init).
    *   Uses a dedicated AWS Key Pair.
*   **Application Load Balancer (ALB):**
    *   Public-facing, deployed across the two dedicated public ALB subnets.
    *   **Listener:** Configured for HTTP on port 80.
    *   **Target Groups:**
        *   `demo04_tg1` (Default): Receives traffic by default. The first two web server instances are attached to this target group.
        *   `demo04_tg2` (Path-Based): Receives traffic for URL paths matching `/mypath/*`. The third web server instance is attached to this target group.
    *   **Listener Rule:** A rule is configured on the HTTP listener to forward requests with path `/mypath/*` to `demo04_tg2`. All other requests go to `demo04_tg1`.
*   **Security Groups:**
    *   **Bastion Security Group:** Allows inbound SSH (TCP port 22) from `authorized_ips`.
    *   **Web Server Security Group:**
        *   Allows inbound HTTP (TCP port 80) from the VPC's CIDR block (primarily for ALB access).
        *   Allows inbound SSH (TCP port 22) from the Bastion's security group.
    *   **ALB Security Group:**
        *   Allows inbound HTTP (TCP port 80) from `authorized_ips` (or `0.0.0.0/0` for public access).
        *   Restricts egress HTTP (TCP port 80) specifically to the Web Server security group.
*   **Network ACLs (NACLs):**
    *   Configured for all public and private subnets to control traffic at the subnet level.
*   **AWS Key Pairs:**
    *   Separate key pairs for the bastion host and the web server instances.

## Architecture

1.  A **VPC** provides the foundational network.
2.  **Public Subnets:**
    *   One in `bastion_az` hosts the **Bastion EC2** (with EIP) and the **NAT Gateway** (with EIP).
    *   Two in `websrv_az` host the **Application Load Balancer**.
3.  **Private Subnets:**
    *   Two in `websrv_az` host the three **Web Server EC2 instances**. These instances use the NAT Gateway for outbound internet.
4.  The **ALB** listens for HTTP traffic on port 80.
    *   Requests to `/mypath/*` are routed to `demo04_tg2` (one web server).
    *   All other requests are routed to `demo04_tg1` (two web servers).
5.  **Security** is managed by Security Groups and Network ACLs.

This setup demonstrates ALB's path-based routing capabilities and a multi-AZ deployment for load balancing and web serving tiers, while utilizing a single bastion and NAT gateway for simplicity in those aspects.

## Key Configuration Variables

Users may need to configure the following variables:

*   `aws_region`: The AWS region (e.g., "us-east-1").
*   `bastion_az`: The Availability Zone for the bastion host and NAT Gateway (e.g., "us-east-1a").
*   `websrv_az`: A list of two Availability Zones for the ALB and web servers (e.g., `["us-east-1b", "us-east-1c"]`).
*   `cidr_vpc`: CIDR block for the VPC (e.g., "10.30.0.0/16").
*   `cidr_subnet_public_bastion`: CIDR for the bastion's public subnet.
*   `cidr_subnets_public_lb`: List of CIDRs for the ALB public subnets.
*   `cidr_subnets_private_ws`: List of CIDRs for the web server private subnets.
*   `authorized_ips`: List of IPs/CIDRs for SSH to bastion and HTTP to ALB (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `websrv_inst_type`: EC2 instance type for web servers.
*   `bastion_inst_type`: EC2 instance type for the bastion.
*   `bastion_key_pair_public_key_path`: Path to the public key for the bastion.
*   `web_key_pair_public_key_path`: Path to the public key for web servers.
*   `bastion_cloud_init_script_path`: Path to bastion's cloud-init script.
*   `web_cloud_init_script_path`: Path to web server's cloud-init script.

## Usage

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

2.  **Plan Changes:**
    ```bash
    terraform plan
    ```

3.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

After deployment, access the web application via the ALB's DNS name. Traffic to `/mypath/*` will be served by one backend server, while other paths will be served by a different set of servers. SSH to the bastion using its EIP for administrative access.
