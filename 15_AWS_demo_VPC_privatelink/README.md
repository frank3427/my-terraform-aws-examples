# AWS PrivateLink Demonstration

## Overview

This Terraform project demonstrates AWS PrivateLink, a technology that enables private and secure connectivity between a service provider VPC and one or more service consumer VPCs. This connection occurs over the AWS backbone, without using the public internet, VPC peering, Transit Gateway, or requiring NAT Gateways for the private service traffic. It allows consumers to access services hosted in another VPC as if they were hosted directly in their own VPC.

The setup involves two main VPCs:
1.  **Service Provider VPC (`demo15-pvd-vpc`):** Hosts the actual service (web servers fronted by a Network Load Balancer).
2.  **Service Consumer VPC (`demo15-csm-vpc`):** Consumes the service offered by the provider VPC via a VPC Interface Endpoint.

The architecture is illustrated in `diagram.png`.

## Service Provider VPC (`demo15-pvd-vpc`) Details

This VPC is designed to host and expose a service via AWS PrivateLink.

*   **Network Configuration:**
    *   One **public subnet**: Hosts the Bastion Host and the Network Load Balancer (NLB).
    *   One **private subnet**: Hosts the backend web server EC2 instances.
    *   Includes an **Internet Gateway (IGW)** for internet access from the public subnet (e.g., for the bastion host).
    *   Includes a **NAT Gateway** in the public subnet to allow instances in the private subnet to initiate outbound connections (e.g., for OS updates), though not strictly required for the PrivateLink service itself.
*   **Application Servers:**
    *   Two **EC2 instances** acting as web servers are deployed in the private subnet. These instances serve the application content (e.g., a simple web page on port 80).
*   **Network Load Balancer (NLB):**
    *   Resource: `aws_lb.demo15_pvd_nlb`.
    *   Type: Public-facing Network Load Balancer, deployed in the public subnet.
    *   Function: Listens on TCP port 80 and forwards traffic to the target group consisting of the two web server EC2 instances in the private subnet.
*   **Bastion Host:**
    *   An **EC2 instance** is deployed in the public subnet. This allows for secure administrative access to resources within the provider VPC (e.g., the web servers).
*   **VPC Endpoint Service (`aws_vpc_endpoint_service.demo15_pvd`):**
    *   This is the core component that makes the service available via PrivateLink.
    *   It is associated with the Network Load Balancer (`aws_lb.demo15_pvd_nlb`).
    *   `acceptance_required = false`: For this demonstration, connection requests to this endpoint service are automatically accepted. In a production scenario, you might set this to `true` for manual approval of consumer connections.

## Service Consumer VPC (`demo15-csm-vpc`) Details

This VPC consumes the service exposed by the Service Provider VPC.

*   **Network Configuration:**
    *   A single **public subnet**.
    *   Includes an **Internet Gateway (IGW)** for internet access (e.g., for the bastion host).
*   **Bastion Host (Consumer):**
    *   Resource: `aws_instance.demo15_csm_bastion`.
    *   An **EC2 instance** is deployed in the public subnet.
    *   Purpose: This instance is used to test connectivity to the provider's service through the VPC Interface Endpoint.
*   **VPC Interface Endpoint (`aws_vpc_endpoint.demo15_csm`):**
    *   **Type:** "Interface". Interface endpoints create Elastic Network Interfaces (ENIs) in the specified subnets within the consumer VPC.
    *   **Service Connection:** It connects to the `service_name` attribute of the provider's VPC Endpoint Service (`aws_vpc_endpoint_service.demo15_pvd`).
    *   **Deployment:** Deployed into the consumer's public subnet, creating ENIs that receive private IP addresses from the subnet's CIDR range.
    *   **Security Group:** Associated with its own security group (`aws_security_group.demo15_csm_sg_endp`). This security group is configured to allow HTTP traffic (TCP port 80) from within the consumer's public subnet (specifically from the consumer bastion's security group or IP).
    *   `private_dns_enabled = false`: For this demo, private DNS is not enabled. This means the service will be accessed using the DNS names provided by the VPC Interface Endpoint itself, not by overriding the service's original DNS name.

## Connectivity Flow

1.  The **Service Consumer VPC** has a **VPC Interface Endpoint** (`aws_vpc_endpoint.demo15_csm`) deployed within its public subnet. This endpoint has one or more Elastic Network Interfaces (ENIs), each with a private IP address from the consumer VPC's subnet.
2.  When the **Consumer Bastion Host** (in the consumer VPC) makes a request to the service (e.g., using `curl` to one of the DNS names of the VPC Interface Endpoint), the traffic is directed to one of these local ENIs.
3.  AWS PrivateLink then privately and securely routes this traffic from the consumer's ENI, across the AWS backbone, directly to the **Network Load Balancer (NLB)** in the **Service Provider VPC**.
4.  The NLB in the provider VPC receives the traffic and distributes it to one of the backend **web server EC2 instances** in its private subnet.
5.  The response traffic follows the reverse path, again all managed privately by AWS PrivateLink.

This entire flow occurs without traffic traversing the public internet, and without the need for VPC Peering, Transit Gateway, or consumer-side NAT Gateways for this specific service communication.

## Key Configuration Variables

Refer to `01_variables.tf` for a complete list. Key variables include:

*   `aws_region`: The AWS region for deploying both VPCs.
*   `az_pvd_list`: Availability Zones for the provider VPC resources.
*   `az_csm_list`: Availability Zones for the consumer VPC resources.
*   `cidr_pvd_vpc`, `cidr_pvd_subnet_public`, `cidr_pvd_subnet_private`: CIDR blocks for the provider VPC.
*   `cidr_csm_vpc`, `cidr_csm_subnet_public`: CIDR blocks for the consumer VPC.
*   `authorized_ips`: Your public IP address for SSH access to bastion hosts.
*   `al2_ami_id` / `al2023_ami_id`: AMIs for EC2 instances.
*   Instance types for bastion and web server instances.
*   SSH key names.

## Usage Instructions

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
    You will be prompted to confirm the action. Type `yes` to proceed.

## Testing the Setup

1.  **SSH into the Consumer Bastion Host:**
    *   Obtain the public IP address of the `demo15_csm_bastion` instance from the Terraform outputs or the AWS EC2 console.
    *   Use your SSH key to connect:
        ```bash
        ssh -i /path/to/your/ssh-key.pem ec2-user@<Consumer_Bastion_Public_IP>
        ```

2.  **Access the Service via the VPC Interface Endpoint:**
    *   The VPC Interface Endpoint (`aws_vpc_endpoint.demo15_csm`) will have one or more DNS names associated with it. These can be found in the Terraform output for `aws_vpc_endpoint.demo15_csm.dns_entry` or in the AWS VPC console under "Endpoints".
    *   From the consumer bastion host's command line, use `curl` or another HTTP client to make a request to one of these DNS names. Since the service is on port 80, no port needs to be specified in the URL for HTTP.
        ```bash
        # Example: dns_entries is a list, pick one.
        # Let's assume one of the DNS names is vpce-xxxxxxxxxxxxxxxxx-yyyyyyyyy.vpce-svc-zzzzzzzzzzzzzzzzz.region.vpce.amazonaws.com
        curl http://<DNS_Name_of_VPC_Interface_Endpoint_ENI>
        ```
    *   You should receive a response from one of the web servers in the Service Provider VPC's private subnet, demonstrating successful private connectivity via AWS PrivateLink.

This test confirms that the consumer EC2 instance can access the service hosted in the provider VPC privately, without the traffic going over the public internet. The `diagram.png` in this directory visually represents this architecture.I have updated the `README.md` file for the `15_AWS_demo_VPC_privatelink/` directory by overwriting it with the new content.

The updated README now includes:
-   The retained summary points from the original file, integrated into the detailed descriptions.
-   A new **Overview** section explaining AWS PrivateLink's purpose and benefits in this context.
-   Detailed **Service Provider VPC (`demo15-pvd-vpc`) Details**, covering its network setup, application servers (two EC2 instances), the Network Load Balancer (`aws_lb.demo15_pvd_nlb`), a bastion host, and the VPC Endpoint Service (`aws_vpc_endpoint_service.demo15_pvd`) with `acceptance_required = false`.
-   Detailed **Service Consumer VPC (`demo15-csm-vpc`) Details**, covering its network, bastion host (`aws_instance.demo15_csm_bastion`), and the VPC Interface Endpoint (`aws_vpc_endpoint.demo15_csm`) including its type ("Interface"), connection to the provider's service, ENI deployment in the consumer's public subnet, its security group (`aws_security_group.demo15_csm_sg_endp`), and `private_dns_enabled = false`.
-   A **Connectivity Flow** section explaining how traffic routes from the consumer bastion to the provider's web servers via the Interface Endpoint and NLB, all privately.
-   A placeholder for **Key Configuration Variables** (directing users to `01_variables.tf`).
-   Standard **Usage Instructions** for Terraform.
-   A **Testing the Setup** section, guiding users to SSH into the consumer bastion and use `curl` with the VPC Interface Endpoint's DNS names (`aws_vpc_endpoint.demo15_csm.dns_entry`) to reach the provider's service. It also mentions the `diagram.png`.

All specified requirements have been addressed in the updated `README.md`.
