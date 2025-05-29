# Terraform AWS: Web Application with Classic Load Balancer (CLB)

This Terraform project demonstrates how to provision a web application infrastructure on AWS using a **Classic Load Balancer (CLB)** to distribute traffic to EC2 instances. The setup includes a custom VPC with public and private subnets, a NAT Gateway, a bastion host for secure access, and EC2 instances serving as web servers.

## Important Note on Classic Load Balancers (CLB)

**Classic Load Balancers are a previous generation of load balancers in AWS.** While this project demonstrates their use for educational or legacy system understanding purposes, AWS now recommends using **Application Load Balancers (ALB)** or **Network Load Balancers (NLB)** for new applications. ALBs and NLBs offer more advanced features, better performance, and more flexible pricing.

Consider this project a demonstration of older AWS technology rather than a template for modern deployments.

## Key Features & Concepts

*   **Classic Load Balancer (`aws_elb`):** An older generation AWS load balancer that operates at both Layer 4 (TCP) and Layer 7 (HTTP/HTTPS). This demo uses it for HTTP load balancing.
*   **Direct Instance Registration:** Unlike ALBs/NLBs that use Target Groups, EC2 instances are directly registered with the Classic Load Balancer.
*   **Multi-AZ Deployment:** The CLB is deployed across multiple public subnets in different Availability Zones, and EC2 instances are in private subnets across these AZs for basic high availability.
*   **Private Subnets for Application Instances:** EC2 instances running the web application are placed in private subnets for enhanced security.
*   **NAT Gateway:** Provides outbound internet connectivity for instances in private subnets.
*   **Bastion Host:** A secure entry point for SSH access to instances in private subnets.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   Configured with public and private subnets across multiple Availability Zones (e.g., `var.az_list`).
    *   **Public Subnets:** Used for the Bastion Host and the Classic Load Balancer.
    *   **Private Subnets:** Used for the EC2 web server instances.
    *   Includes an Internet Gateway (IGW) attached to the VPC.
*   **NAT Gateway:**
    *   Deployed in one of the public subnets with an Elastic IP.
    *   Provides outbound internet connectivity for instances in the private subnets.
*   **Bastion Host:**
    *   An EC2 instance launched in a public subnet for secure SSH access.
*   **Classic Load Balancer (CLB) (`aws_elb.demo22_clb`):**
    *   Deployed across the specified public subnets.
    *   **Instance Registration:** EC2 web server instances are directly specified in the `instances` argument of the `aws_elb` resource.
    *   **Listeners:** Configured with an HTTP listener on port 80, forwarding traffic to port 80 on the backend instances.
    *   **Health Checks:** Configured to perform health checks on the backend EC2 instances (e.g., HTTP checks on a specific path).
    *   Associated with its own security group (`aws_security_group.demo22_sg_clb`).
*   **EC2 Instances (Web Servers):**
    *   Multiple EC2 instances (e.g., Amazon Linux 2) launched in the private subnets.
    *   Configured with a user data script to install a simple web server (e.g., Apache or Nginx) and a test page.
    *   Serve as the backend for the Classic Load Balancer.
*   **Security Groups:**
    *   **CLB Security Group (`aws_security_group.demo22_sg_clb`):**
        *   Inbound: Allows HTTP (TCP port 80) from `authorized_ips` (or `0.0.0.0/0` for public web access).
        *   Outbound: Allows HTTP (TCP port 80) to the Web Server Security Group.
    *   **Web Server Security Group (`aws_security_group.demo22_sg_websrv`):**
        *   Used by the web server EC2 instances.
        *   Inbound:
            *   Allows HTTP (TCP port 80) from the VPC's CIDR block (specifically allowing traffic from the CLB). Note: CLBs, unlike ALBs, don't have a specific SG to source traffic from; often, rules allow from the CLB's subnets or the broader VPC CIDR.
            *   Allows SSH (TCP port 22) from the Bastion Host's Security Group.
        *   Outbound: Allows all traffic (or specific traffic needed by the application, including to the NAT Gateway).
    *   **Bastion Security Group (`aws_security_group.demo22_sg_bastion`):**
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
        |  | Bastion Host (EC2)  |      | Classic Load Balancer (CLB)       |  |
        |  | (SG: Bastion SG)    |<-----+ (Public, Spans Public Subnets)    |  |
        |  |      EIP            |      | (SG: CLB SG)                      |  |
        |  +---------------------+      +-------------+---------------------+  |
        |           | (SSH via IGW)                   | (HTTP via IGW)         |
        |           |                                 ▼                        |
        |-----------|--------------- Private Subnets (Multi-AZ) ---------------|
        |           | (SSH)          +-----------------------------------+     |
        |           |                | EC2 Web Server Instances          |     |
        |           +--------------->|  - Instance 1 (Private IP)        |<----+(Directly Registered)
        |                            |  - Instance 2 (Private IP)        |     |
        |                            |  (User Data for Web Server)       |     |
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
Users access the web application via the CLB's DNS name. The CLB distributes traffic to the EC2 instances directly registered with it, located in private subnets. These instances can make outbound connections via the NAT Gateway. Secure SSH access to web instances is via the Bastion Host.

## Key Configuration Variables

*   **General AWS & VPC:** `aws_region`, `az_list` (list of AZs), `cidr_vpc`, `cidrs_subnet_public`, `cidrs_subnet_private`, `authorized_ips`.
*   **Bastion Host:** `bastion_inst_type`, `bastion_ssh_key_name`.
*   **Web Server Instances:** `web_inst_type`, `web_ssh_key_name`, user data script path.
*   **Classic Load Balancer:**
    *   Listener configuration (e.g., instance port, LB port, protocol).
    *   Health check configuration (e.g., target, interval, timeout).

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

1.  **Find the CLB DNS Name:**
    Obtain the DNS name of the Classic Load Balancer (`aws_elb.demo22_clb`) from the Terraform outputs (e.g., `clb_dns_name`) or the AWS EC2 console under "Load Balancers (Classic)".

2.  **Access the Web Application:**
    Open a web browser and navigate to `http://<CLB_DNS_Name>`.
    You should see the test page served by one of the EC2 instances registered with the CLB. Refreshing the page might hit different instances if multiple are running and healthy.

This project provides a functional example of using a Classic Load Balancer. For any new development, strongly consider using Application Load Balancers or Network Load Balancers.
