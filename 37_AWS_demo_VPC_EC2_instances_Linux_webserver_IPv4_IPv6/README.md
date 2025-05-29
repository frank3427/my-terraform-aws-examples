# Terraform AWS: Dual-Stack (IPv4 & IPv6) VPC with EC2 Web Servers

This Terraform project demonstrates how to provision a **dual-stack Virtual Private Cloud (VPC)** on AWS, supporting both IPv4 and IPv6 addressing. It launches Linux EC2 instances configured as web servers that are accessible over both IPv4 and IPv6.

## Purpose

The primary goal of this project is to illustrate the setup and configuration required for a fully dual-stack environment on AWS. This includes:
*   Enabling IPv6 on a VPC and its subnets.
*   Assigning IPv6 addresses to EC2 instances.
*   Configuring routing for both IPv4 and IPv6 internet traffic.
*   Setting up Network ACLs (NACLs) and Security Groups to allow dual-stack traffic (HTTP and SSH).
*   Deploying simple web servers accessible via both their public IPv4 (Elastic IP) and public IPv6 addresses.

This setup is essential for applications that need to support IPv6 clients or operate in IPv6-only or dual-stack network environments.

## Key Components

1.  **Dual-Stack VPC (`aws_vpc.demo37`):**
    *   **IPv4 CIDR Block:** Configured with a traditional IPv4 CIDR block (e.g., from `var.cidr_vpc`).
    *   **IPv6 CIDR Block:** `assign_generated_ipv6_cidr_block = true`. This instructs AWS to associate an Amazon-provided /56 IPv6 CIDR block with the VPC.
2.  **Internet Gateway & Routing:**
    *   An **Internet Gateway (`aws_internet_gateway`)** is created and attached to the VPC to enable communication with the internet for both IPv4 and IPv6.
    *   The **Default Route Table (`aws_default_route_table.demo37`)** for the VPC is configured with routes for:
        *   IPv4 internet traffic: `0.0.0.0/0` pointing to the Internet Gateway.
        *   IPv6 internet traffic: `::/0` (all IPv6 addresses) pointing to the Internet Gateway.
3.  **Dual-Stack Public Subnets (`aws_subnet.demo37_public1`, `aws_subnet.demo37_public2`):**
    *   Two public subnets are created in different Availability Zones for high availability.
    *   Each subnet is assigned both:
        *   An **IPv4 CIDR block** (a portion of the VPC's IPv4 CIDR).
        *   An **IPv6 CIDR block** (e.g., a /64 prefix derived from the VPC's /56 IPv6 range using `ipv6_cidr_block` attribute with `cidrsubnet` interpolation).
    *   `assign_ipv6_address_on_creation = true`: This setting ensures that EC2 instances launched into these subnets are automatically assigned an IPv6 address from the subnet's IPv6 range upon creation.
    *   `map_public_ip_on_launch = true`: For IPv4 public IP assignment (though EIPs are used for static public IPv4).
4.  **EC2 Instances (Web Servers):**
    *   Two Amazon Linux 2 instances are launched, one in each public subnet.
    *   **IPv4 Configuration:**
        *   Each instance receives a primary private IPv4 address.
        *   An **Elastic IP (EIP - `aws_eip`)** is associated with each instance for a static public IPv4 address.
    *   **IPv6 Configuration:**
        *   Each instance is assigned an IPv6 address from its subnet's IPv6 range.
        *   The project demonstrates both:
            *   Automatic assignment (due to `assign_ipv6_address_on_creation = true` on the subnet).
            *   One instance (`aws_instance.demo37_al2_inst1`) demonstrates a **static assignment of an IPv6 address** (`ipv6_addresses = [cidrsubnet(aws_subnet.demo37_public1.ipv6_cidr_block, 8, 101)]`) from within the subnet's IPv6 range.
    *   **Cloud-Init Script (`user_data`):**
        *   A simple script installs Apache (`httpd`) and PHP.
        *   It creates a basic `index.php` page that displays the instance's hostname, allowing for easy identification of which web server is responding.
5.  **Network ACLs (`aws_default_network_acl.demo37`):**
    *   The default Network ACL for the VPC is configured to be stateless and allow:
        *   **Inbound:**
            *   SSH (TCP port 22) from specified IPv4 source addresses (`var.authorized_ips`) and IPv6 source addresses (`var.authorized_ips_v6`).
            *   HTTP (TCP port 80) from specified IPv4 (`var.authorized_ips`) and IPv6 (`var.authorized_ips_v6`) source addresses.
            *   Ephemeral ports for return traffic.
        *   **Outbound:** All traffic is allowed for both IPv4 and IPv6.
6.  **Security Groups (`aws_default_security_group.demo37`):**
    *   The default Security Group for the VPC is used for the EC2 instances and configured to allow:
        *   **Inbound:**
            *   SSH (TCP port 22) from specified IPv4 source addresses (`var.authorized_ips`) and IPv6 source addresses (`var.authorized_ips_v6`).
            *   HTTP (TCP port 80) from specified IPv4 (`var.authorized_ips`) and IPv6 source addresses (`var.authorized_ips_v6`).
        *   **Outbound:** All traffic is allowed for both IPv4 and IPv6.
        *   **Intra-VPC IPv6:** An additional rule allows all IPv6 traffic from the VPC's own IPv6 CIDR block, facilitating inter-instance communication over IPv6 within the VPC if needed.

## Network Configuration (Dual-Stack) Highlights

*   **VPC IPv6 Enablement:** The `assign_generated_ipv6_cidr_block = true` argument on the `aws_vpc` resource is the first step to enable IPv6. AWS assigns a /56 IPv6 CIDR block.
*   **Subnet IPv6 CIDR Allocation:** Each subnet is explicitly assigned a portion of the VPC's IPv6 range (typically a /64) using the `ipv6_cidr_block` argument.
*   **Instance IPv6 Assignment:** Achieved via `assign_ipv6_address_on_creation = true` on the subnet and can also be done explicitly using `ipv6_addresses` on the `aws_instance` resource.
*   **Routing for IPv6:** A route for `::/0` to the Internet Gateway in the route table is essential for IPv6 internet connectivity.
*   **Security for Dual-Stack:** Both Security Groups and Network ACLs must have rules that explicitly allow desired IPv6 traffic, in addition to IPv4 rules.

## Highlights

*   **End-to-End IPv6:** Demonstrates a complete dual-stack setup from VPC creation to EC2 instance accessibility over IPv6.
*   **IPv6 Address Management:** Shows both automatic and static assignment of IPv6 addresses to EC2 instances.
*   **Dual-Stack Security Rules:** Emphasizes the need to configure Security Groups and NACLs for both IPv4 and IPv6 traffic.
*   **Web Server Accessibility:** The deployed web servers can be reached using their public IPv4 addresses (EIPs) and their public IPv6 addresses.

## Key Configuration Variables

*   `aws_region`: The AWS region for deployment (e.g., "us-east-1").
*   `az_list`: A list of two Availability Zones for the public subnets.
*   `cidr_vpc`: The IPv4 CIDR block for the VPC.
*   `authorized_ips`: A list of IPv4 CIDR blocks allowed for SSH and HTTP access.
*   `authorized_ips_v6`: A list of IPv6 CIDR blocks allowed for SSH and HTTP access (e.g., `["::/0"]` to allow all IPv6, or more specific prefixes).
*   `inst_type`: EC2 instance type (e.g., "t2.micro").
*   `al2_ssh_key_name`: Name of an existing EC2 Key Pair.

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
    Confirm by typing `yes`. Terraform will output the public IPv4 (EIPs) and public IPv6 addresses of the EC2 instances.

## Testing Connectivity

After successful deployment:

1.  **Note EC2 Instance IPs:**
    Get the `Instance1_EIP`, `Instance1_IPv6_Address`, `Instance2_EIP`, and `Instance2_IPv6_Address` from the Terraform output.

2.  **Test IPv4 Access:**
    *   Open a web browser or use `curl` to access each instance via its public IPv4 EIP:
        ```bash
        curl http://<Instance1_EIP>
        curl http://<Instance2_EIP>
        ```
    *   You should see the test page displaying the hostname of the respective instance.

3.  **Test IPv6 Access:**
    *   This requires your local machine or testing environment to have IPv6 connectivity.
    *   Open a web browser or use `curl` (with appropriate flags for IPv6) to access each instance via its public IPv6 address:
        ```bash
        # For curl, use -g to disable globbing and -6 to force IPv6
        # The IPv6 address should be enclosed in square brackets in the URL for HTTP
        curl -g -6 "http://[<Instance1_IPv6_Address>]"
        curl -g -6 "http://[<Instance2_IPv6_Address>]"
        ```
    *   You should see the test page displaying the hostname of the respective instance.

4.  **Test SSH (IPv4 and IPv6):**
    *   Ensure your local machine's IP (IPv4 and/or IPv6) is included in `var.authorized_ips` and `var.authorized_ips_v6` respectively.
    *   **IPv4 SSH:**
        ```bash
        ssh -i /path/to/your/ssh-key.pem ec2-user@<Instance1_EIP>
        ```
    *   **IPv6 SSH (if your local network supports it):**
        ```bash
        ssh -i /path/to/your/ssh-key.pem ec2-user@<Instance1_IPv6_Address>
        ```

Successful access via both IPv4 and IPv6 addresses confirms the dual-stack configuration is working correctly.
