# Terraform AWS VPC with NLB and Web Servers in a Single AZ

This Terraform project provisions a complete network infrastructure in a single AWS Availability Zone (AZ). It includes a new VPC, public and private subnets, a bastion host for secure access, a public Network Load Balancer (NLB), and two web server instances running in the private subnet.

## AWS Resources Provisioned

This project will create the following AWS resources in a single Availability Zone:

*   **VPC (Virtual Private Cloud):**
    *   A new VPC to provide an isolated network environment.
    *   **Internet Gateway (IGW):** Attached to the VPC to enable communication with the internet.
*   **Public Subnet:**
    *   Hosts resources that need direct internet access.
    *   Configured with a default route to the Internet Gateway.
    *   **Bastion EC2 Instance:**
        *   An Amazon Linux 2023 (AL2023) ARM64 instance.
        *   Associated with an **Elastic IP (EIP)** for a static public IP address.
        *   Allows SSH access from authorized IP addresses for secure administrative access to other resources.
        *   Uses a dedicated AWS Key Pair.
    *   **Network Load Balancer (NLB):**
        *   A public NLB to distribute incoming traffic to the web servers.
    *   **NAT Gateway:**
        *   Deployed in the public subnet with an Elastic IP.
        *   Enables instances in the private subnet to initiate outbound internet connections (e.g., for software updates) while preventing inbound connections initiated from the internet.
*   **Private Subnet:**
    *   Hosts backend resources that should not be directly accessible from the internet.
    *   Configured with a default route to the NAT Gateway for outbound internet access.
    *   **Web Server EC2 Instances (x2):**
        *   Two Amazon Linux 2023 (AL2023) ARM64 instances.
        *   These instances run a simple web service (e.g., Apache or Nginx, typically configured via a cloud-init script) serving content on TCP port 80.
        *   Uses a dedicated AWS Key Pair (can be the same or different from the bastion's).
*   **Networking and Security:**
    *   **Route Tables:** Separate route tables for public and private subnets.
    *   **Network ACLs (NACLs):**
        *   Configured for both public and private subnets to control traffic flow at the subnet level.
    *   **Security Groups:**
        *   **Bastion Security Group:** Allows inbound SSH (TCP port 22) from `authorized_ips`.
        *   **Web Server Security Group:**
            *   Allows inbound HTTP (TCP port 80) from `authorized_ips` (for direct access if needed, though primarily accessed via NLB) and from the public subnet (for NLB health checks).
            *   Allows inbound SSH (TCP port 22) from the public subnet (specifically from the bastion's IP/security group).
*   **Network Load Balancer (NLB) Components:**
    *   **Target Group:**
        *   For the two web server instances.
        *   Listens on TCP port 80.
        *   Uses TCP health checks to monitor the health of the web servers.
    *   **Listener:**
        *   Attached to the NLB.
        *   Listens on TCP port 80 and forwards traffic to the web server target group.
*   **AWS Key Pairs:**
    *   Separate key pairs are typically created for the bastion host and the web server instances to enhance security.

## Architecture

The architecture consists of:
1.  A **VPC** spanning a single Availability Zone.
2.  A **Public Subnet** containing:
    *   A **Bastion Host** (EC2) with an EIP for secure SSH entry.
    *   A **NAT Gateway** with an EIP for outbound internet from the private subnet.
    *   A **Public Network Load Balancer (NLB)** distributing traffic to web servers.
3.  A **Private Subnet** containing:
    *   Two **Web Server EC2 instances** serving content on TCP port 80. These instances receive traffic from the NLB and can initiate outbound connections via the NAT Gateway.
4.  **Security** is managed via Network ACLs and Security Groups. The web servers are not directly exposed to the internet for incoming application traffic; access is brokered by the NLB and the bastion host.

The web servers are expected to serve content on TCP port 80, which is made accessible externally through the Network Load Balancer's public IP address.

## Key Configuration Variables

Users may need to configure the following variables in their Terraform configuration (e.g., in a `terraform.tfvars` file or via command-line arguments):

*   `aws_region`: The AWS region where the resources will be deployed (e.g., "us-east-1").
*   `az`: The Availability Zone for resource deployment (e.g., "us-east-1a").
*   `cidr_vpc`: The CIDR block for the new VPC (e.g., "10.10.0.0/16").
*   `cidr_subnet_public`: The CIDR block for the public subnet (e.g., "10.10.1.0/24").
*   `cidr_subnet_private`: The CIDR block for the private subnet (e.g., "10.10.2.0/24").
*   `authorized_ips`: A list of IP addresses or CIDR blocks authorized for SSH access to the bastion and HTTP access to the NLB/web servers (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `websrv_inst_type`: The EC2 instance type for the web servers (e.g., "t3.micro").
*   `bastion_inst_type`: The EC2 instance type for the bastion host (e.g., "t3.nano").
*   `bastion_key_pair_public_key_path`: Path to the public key for the bastion's key pair.
*   `web_key_pair_public_key_path`: Path to the public key for the web servers' key pair.
*   `bastion_cloud_init_script_path`: Path to the cloud-init script for bastion configuration.
*   `web_cloud_init_script_path`: Path to the cloud-init script for web server setup (e.g., installing a web server).

## Usage

1.  **Initialize Terraform:**
    Navigate to the directory containing the Terraform files and run:
    ```bash
    terraform init
    ```

2.  **Plan Changes (Optional but Recommended):**
    Review the resources that Terraform will create:
    ```bash
    terraform plan
    ```

3.  **Apply Changes:**
    Provision the AWS resources:
    ```bash
    terraform apply
    ```
    You will be prompted to confirm the action. Type `yes` to proceed.

After successful deployment, the web servers will be accessible via the DNS name of the Network Load Balancer on TCP port 80. You can SSH to the bastion host using its Elastic IP and then SSH from the bastion to the web servers if needed.
