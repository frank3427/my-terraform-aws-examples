# Terraform AWS VPC with Multi-AZ NLB and Web Servers

This Terraform project provisions a robust and highly available network infrastructure across multiple AWS Availability Zones (AZs). It builds upon the single-AZ NLB setup by distributing resources for increased fault tolerance. The project includes a new VPC, public and private subnets in each specified AZ, a bastion host, a multi-AZ public Network Load Balancer (NLB), and web server instances in each private subnet.

## High Availability

The core design principle of this project is high availability. By deploying resources across multiple Availability Zones, the application can withstand the failure of a single AZ.
-   **Public and Private Subnets:** Created in each specified AZ.
-   **Web Servers:** One instance is deployed in each private subnet/AZ, ensuring application availability even if one AZ goes down.
-   **NAT Gateways:** One NAT Gateway is deployed in each public subnet/AZ, providing resilient outbound internet access for the private subnet in the same AZ.
-   **Network Load Balancer (NLB):** Spans all specified public subnets/AZs, distributing traffic to healthy web server instances across all AZs.

## AWS Resources Provisioned

This project will create the following AWS resources, distributed across the specified Availability Zones:

*   **VPC (Virtual Private Cloud):**
    *   A new VPC to provide an isolated network environment.
    *   **Internet Gateway (IGW):** Attached to the VPC to enable communication with the internet.
*   **Public Subnets (Multiple):**
    *   One public subnet created in each specified Availability Zone (controlled by `var.nb_az` and `var.az`).
    *   Each public subnet is configured with a default route to the Internet Gateway.
    *   **Bastion EC2 Instance:**
        *   A single Amazon Linux 2023 (AL2023) ARM64 instance.
        *   Located in the **first** public subnet (e.g., `public_subnets[0]`).
        *   Associated with an **Elastic IP (EIP)** for a static public IP address.
        *   Allows SSH access from `authorized_ips` for secure administrative access.
        *   Uses a dedicated AWS Key Pair.
    *   **Network Load Balancer (NLB):**
        *   A public NLB configured to span across **all public subnets** in the specified AZs.
    *   **NAT Gateways (Multiple):**
        *   One NAT Gateway deployed in **each public subnet/AZ**.
        *   Each NAT Gateway has its own **Elastic IP (EIP)**.
        *   Provides outbound internet connectivity for resources in the corresponding private subnet in the same AZ.
*   **Private Subnets (Multiple):**
    *   One private subnet created in each specified Availability Zone.
    *   Each private subnet is configured with a default route to the NAT Gateway in its respective AZ.
    *   **Web Server EC2 Instances (Multiple):**
        *   One Amazon Linux 2023 (AL2023) ARM64 instance deployed in **each private subnet/AZ**.
        *   These instances run a simple web service (e.g., Apache or Nginx via cloud-init) serving content on TCP port 80.
        *   Uses a dedicated AWS Key Pair.
*   **Networking and Security:**
    *   **Route Tables:** Separate route tables for each public and private subnet, adapted for multi-AZ routing.
    *   **Network ACLs (NACLs):**
        *   Configured for both public and private subnets to control traffic flow at the subnet level, adapted for multi-AZ.
    *   **Security Groups:**
        *   **Bastion Security Group:** Allows inbound SSH (TCP port 22) from `authorized_ips`.
        *   **Web Server Security Group:**
            *   Allows inbound HTTP (TCP port 80) from `authorized_ips` (for direct access if needed) and from **all public subnets** (for NLB health checks and traffic).
            *   Allows inbound SSH (TCP port 22) from **all public subnets** (to allow bastion access to any web server).
*   **Network Load Balancer (NLB) Components:**
    *   **Target Group:**
        *   Includes **all web server instances** from all private subnets/AZs.
        *   Listens on TCP port 80.
        *   Uses TCP health checks to monitor the health of the web servers.
    *   **Listener:**
        *   Attached to the NLB.
        *   Listens on TCP port 80 and forwards traffic to the multi-AZ web server target group.
*   **AWS Key Pairs:**
    *   Separate key pairs for the bastion host and the web server instances.

## Architecture

The multi-AZ architecture is designed for resilience:
1.  A **VPC** spanning multiple Availability Zones.
2.  **Multiple Public Subnets** (one per AZ), each containing:
    *   A **NAT Gateway** with an EIP (for the corresponding private subnet).
    *   The **Bastion Host** (EC2, EIP) resides in the *first* public subnet.
    *   The **Public Network Load Balancer (NLB)** is associated with all public subnets, distributing traffic across AZs.
3.  **Multiple Private Subnets** (one per AZ), each containing:
    *   A **Web Server EC2 instance** serving content on TCP port 80. These instances receive traffic from the NLB and initiate outbound connections via the NAT Gateway in their respective AZ.
4.  **Security** is managed via Network ACLs and Security Groups, adapted for multi-AZ access patterns. Web servers are fronted by the NLB.

The web servers serve content on TCP port 80, accessible externally via the NLB's public DNS name.

## Key Configuration Variables

Users may need to configure the following variables:

*   `aws_region`: The AWS region (e.g., "us-east-1").
*   `nb_az`: The number of Availability Zones to use (e.g., 2 or 3).
*   `az`: A list of Availability Zone names (e.g., `["us-east-1a", "us-east-1b"]`). The length of this list must match `nb_az`.
*   `cidr_vpc`: The CIDR block for the VPC (e.g., "10.20.0.0/16").
*   `cidr_subnet_public`: A list of CIDR blocks for the public subnets, one per AZ (e.g., `["10.20.1.0/24", "10.20.2.0/24"]`).
*   `cidr_subnet_private`: A list of CIDR blocks for the private subnets, one per AZ (e.g., `["10.20.101.0/24", "10.20.102.0/24"]`).
*   `authorized_ips`: A list of IP addresses/CIDRs for SSH to bastion and HTTP to NLB/web servers (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `websrv_inst_type`: EC2 instance type for web servers (e.g., "t3.micro").
*   `bastion_inst_type`: EC2 instance type for the bastion host (e.g., "t3.nano").
*   `bastion_key_pair_public_key_path`: Path to the public key for the bastion's key pair.
*   `web_key_pair_public_key_path`: Path to the public key for the web servers' key pair.
*   `bastion_cloud_init_script_path`: Path to the cloud-init script for bastion configuration.
*   `web_cloud_init_script_path`: Path to the cloud-init script for web server setup.

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

After deployment, access the web application via the NLB's DNS name. SSH to the bastion using its EIP, then to web servers if needed.
