# Terraform AWS VPC with ALB, Route 53 DNS, and HTTPS (ACM)

This Terraform project extends the `04_AWS_demo_VPC_ELB_ALB` setup by integrating AWS Route 53 for DNS management and AWS Certificate Manager (ACM) to enable HTTPS on the Application Load Balancer (ALB). It demonstrates how to secure web applications with custom domain names and SSL/TLS certificates.

## Key Features

*   **Builds on `04_AWS_demo_VPC_ELB_ALB`:** Utilizes the same base infrastructure (VPC, public/private subnets, single bastion, single NAT gateway, web servers).
*   **HTTPS Termination:** The ALB terminates HTTPS traffic, offloading SSL processing from backend servers.
*   **HTTP to HTTPS Redirection:** The ALB automatically redirects all incoming HTTP (port 80) requests to HTTPS (port 443) using an HTTP 301 redirect.
*   **Multiple Custom Domains (SNI):** Supports hosting multiple custom domain names (e.g., `app1.yourdomain.com`, `app2.yourdomain.com`) on the same ALB using Server Name Indication (SNI) with multiple ACM certificates.
*   **AWS Certificate Manager (ACM):** Provisions two separate SSL/TLS certificates using DNS validation.
*   **AWS Route 53 Integration:**
    *   Requires a pre-existing public hosted zone.
    *   Automatically creates DNS records required for ACM certificate validation.
    *   Creates CNAME records for your custom domain names, pointing them to the ALB.

## AWS Resources Provisioned

This project includes all resources from the base `04_AWS_demo_VPC_ELB_ALB` project, with the following key additions and modifications:

*   **Base Infrastructure:**
    *   VPC with Internet Gateway.
    *   Public subnets (for bastion and ALB) and private subnets (for web servers) across specified AZs.
    *   Single Bastion EC2 instance (Amazon Linux 2 ARM64) with EIP.
    *   Single NAT Gateway with EIP, located in the bastion's public subnet.
*   **Application Load Balancer (ALB):**
    *   Public-facing, multi-AZ.
    *   **HTTP Listener (Port 80):**
        *   Configured to perform an automatic redirect (HTTP 301) for all incoming HTTP requests to the HTTPS listener on port 443.
    *   **HTTPS Listener (Port 443):**
        *   Handles incoming HTTPS traffic.
        *   Uses a predefined SSL policy (e.g., `ELBSecurityPolicy-2016-08`).
        *   Supports multiple SSL certificates (one default, one additional via SNI) provisioned by ACM.
        *   Forwards traffic to a single default target group containing the web servers. (Path-based routing from project `04` is not implemented here).
*   **AWS Certificate Manager (ACM):**
    *   Provisions **two separate ACM certificates**.
    *   Certificate validation is performed using DNS records automatically created in the specified Route 53 hosted zone.
*   **AWS Route 53:**
    *   Leverages an existing public hosted zone (specified by `var.dns_zone_id` and `var.dns_domain`).
    *   Creates DNS `CNAME` records for certificate validation for both ACM certificates.
    *   Creates DNS `CNAME` records for two different hostnames (`var.dns_name` and `var.dns_name2`) pointing to the ALB's DNS name, enabling access via these custom domains.
*   **Web Servers:**
    *   Two EC2 instances (Amazon Linux 2 ARM64) running a simple web service on HTTP port 80.
    *   Located in the private subnets, receiving traffic from the ALB.
*   **Security Groups:**
    *   **ALB Security Group:**
        *   Allows inbound HTTP (TCP port 80) and HTTPS (TCP port 443) from `authorized_ips` (or `0.0.0.0/0` for public access).
        *   Egress is typically open to allow traffic to target groups.
    *   **Bastion Security Group:** Allows inbound SSH (TCP port 22) from `authorized_ips`.
    *   **Web Server Security Group:** Allows inbound HTTP (TCP port 80) from the ALB's security group and SSH (TCP port 22) from the Bastion's security group.
*   **Network ACLs (NACLs):**
    *   Updated to permit HTTPS (TCP port 443) traffic to the public subnets hosting the ALB, in addition to HTTP.

## Architecture

1.  A user attempts to access `http://var.dns_name` or `http://var.dns_name2`.
2.  **Route 53** resolves these custom domain names to the ALB's DNS name.
3.  The request hits the ALB's **HTTP listener on port 80**.
4.  The HTTP listener immediately sends an **HTTP 301 redirect** to the client, instructing it to use `https://var.dns_name` (or `https://var.dns_name2`).
5.  The client makes a new request to `https://var.dns_name`.
6.  Route 53 again resolves this to the ALB.
7.  The request hits the ALB's **HTTPS listener on port 443**.
8.  The ALB uses the appropriate **ACM certificate** (selected via SNI based on the requested hostname) to terminate the SSL/TLS connection.
9.  The ALB then forwards the decrypted HTTP request to the target group containing the web servers in the private subnets.
10. Web servers process the request and send an HTTP response back to the ALB, which then encrypts it and sends it to the client.

ACM certificates are validated during provisioning by creating temporary CNAME records in the specified Route 53 public hosted zone.

## Prerequisites

*   **Pre-existing Route 53 Public Hosted Zone:** You must have an existing public hosted zone in AWS Route 53. You will need its `Zone ID` and `Domain Name` for the configuration variables.

## Key Configuration Variables

*   `aws_region`: The AWS region (e.g., "us-east-1").
*   `bastion_az`: AZ for the bastion and NAT Gateway.
*   `websrv_az`: List of two AZs for ALB and web servers.
*   `cidr_vpc`, `cidr_subnet_public_bastion`, `cidr_subnets_public_lb`, `cidr_subnets_private_ws`: Network CIDR blocks.
*   `authorized_ips`: IPs/CIDRs for SSH to bastion and HTTP/HTTPS to ALB.
*   `websrv_inst_type`, `bastion_inst_type`: EC2 instance types.
*   `bastion_key_pair_public_key_path`, `web_key_pair_public_key_path`: Paths to SSH public keys.
*   `bastion_cloud_init_script_path`, `web_cloud_init_script_path`: Paths to cloud-init scripts.
*   **`dns_name`**: The primary custom domain/hostname (e.g., `app1.yourdomain.com`).
*   **`dns_name2`**: The secondary custom domain/hostname (e.g., `app2.yourdomain.com`).
*   **`dns_domain`**: The domain name of your existing Route 53 public hosted zone (e.g., `yourdomain.com`).
*   **`dns_zone_id`**: The Zone ID of your existing Route 53 public hosted zone.

## Usage

1.  **Configure Variables:** Ensure you have `terraform.tfvars` file or have exported environment variables for the required inputs, especially the `dns_*` variables and paths to key files.
2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
3.  **Plan Changes:**
    ```bash
    terraform plan
    ```
4.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

After deployment, your web application should be accessible via `https://<dns_name>` and `https://<dns_name2>`. Any HTTP requests will be automatically redirected to HTTPS. DNS records for ACM validation and for your custom hostnames will be visible in your Route 53 hosted zone.
