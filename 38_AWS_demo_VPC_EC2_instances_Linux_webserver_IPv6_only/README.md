# Terraform AWS: EC2 Web Servers in IPv6-Only Subnets

This Terraform project demonstrates how to provision Linux EC2 instances in **IPv6-only subnets** within a dual-stack VPC. These instances are configured as web servers and are accessible exclusively over IPv6 from the internet.

## Purpose

The primary goal of this project is to illustrate the setup and configuration for deploying resources in an IPv6-only environment on AWS. This is increasingly relevant for applications designed for IPv6-first networks or to conserve IPv4 address space.

This project showcases:
*   Creating IPv6-only subnets within a dual-stack VPC.
*   Launching EC2 instances that operate solely with IPv6 addresses for external communication.
*   Configuring routing, Network ACLs (NACLs), and Security Groups specifically for IPv6 traffic to these instances.
*   Deploying simple web servers accessible only via their public IPv6 addresses.

## Key Components

1.  **VPC (`aws_vpc.demo38`):**
    *   **Dual-Stack Configuration:** The VPC itself is configured to be dual-stack. It has:
        *   An IPv4 CIDR block (e.g., from `var.cidr_vpc`).
        *   An Amazon-provided IPv6 CIDR block (`assign_generated_ipv6_cidr_block = true`).
    *   **Note:** While the VPC supports both protocols, the subnets hosting the EC2 web server instances in this demo are configured as IPv6-only. Other subnets within this VPC could still be dual-stack or IPv4-only if needed.
2.  **Internet Gateway & Routing:**
    *   An **Internet Gateway (`aws_internet_gateway`)** is created and attached to the VPC.
    *   The **Default Route Table (`aws_default_route_table.demo38`)** for the VPC is configured with routes for:
        *   IPv4 internet traffic: `0.0.0.0/0` pointing to the Internet Gateway (relevant for any IPv4 resources in other subnets or VPC-level services).
        *   IPv6 internet traffic: `::/0` (all IPv6 addresses) pointing to the Internet Gateway. This is crucial for the IPv6-only instances to communicate with the internet (e.g., for package downloads during cloud-init, if not using VPC endpoints for services).
3.  **IPv6-Only Public Subnets (`aws_subnet.demo38_public1`, `aws_subnet.demo38_public2`):**
    *   Two public subnets are created in different Availability Zones.
    *   **`ipv6_native = true`:** This critical setting makes these subnets IPv6-only. They do **not** have an associated IPv4 CIDR block.
    *   Each subnet is assigned an **IPv6 CIDR block** (e.g., a /64 prefix derived from the VPC's /56 IPv6 range).
    *   `assign_ipv6_address_on_creation = true`: Ensures EC2 instances launched into these subnets are automatically assigned an IPv6 address.
    *   `enable_dns64 = false` (typically, but can be true if NAT64 is also set up, which is not the focus here).
    *   `map_customer_owned_ip_on_launch = false` (not relevant for IPv6).
    *   `enable_resource_name_dns_aaaa_record_on_launch = true`: Allows resolution of instance DNS names to their IPv6 AAAA records.
4.  **EC2 Instances (Web Servers):**
    *   Two Amazon Linux 2 instances are launched, one in each IPv6-only public subnet.
    *   **IPv6-Only Addressing:**
        *   Each instance is assigned only a **public IPv6 address**. They do not have primary private IPv4 addresses within these subnets, nor are any Elastic IPs (public IPv4) associated with them.
    *   **Cloud-Init Script (`user_data`):**
        *   A simple script installs Apache (`httpd`) and PHP.
        *   It creates a basic `index.php` page that displays the instance's hostname.
5.  **Network ACLs (`aws_default_network_acl.demo38`):**
    *   The default Network ACL for the VPC is configured primarily for IPv6 traffic to and from the instances:
        *   **Inbound:** Allows SSH (TCP port 22) and HTTP (TCP port 80) from specified IPv6 source addresses (`var.authorized_ips_v6`).
        *   **Outbound:** All IPv6 traffic is allowed.
        *   (IPv4 rules might exist for other parts of the VPC but are not the primary concern for these instances).
6.  **Security Groups (`aws_default_security_group.demo38`):**
    *   The default Security Group for the VPC is used for the EC2 instances and configured to allow:
        *   **Inbound:** SSH (TCP port 22) and HTTP (TCP port 80) **only from specified IPv6 source addresses** (`var.authorized_ips_v6`).
        *   **Outbound:** All IPv6 traffic is allowed.
        *   **Intra-VPC IPv6:** An additional rule allows all IPv6 traffic from the VPC's own IPv6 CIDR block.

## Network Configuration (IPv6-Only Subnets) Highlights

*   **`ipv6_native = true`:** This attribute on the `aws_subnet` resource is key to creating an IPv6-only subnet. Instances in such subnets will not have IPv4 addresses.
*   **VPC Remains Dual-Stack:** The VPC itself is still dual-stack. This means you could have other dual-stack or IPv4-only subnets within the same VPC if needed for other services or migration purposes.
*   **Egress-Only Internet Gateway (Not Used Here, but Relevant):** For IPv6-only instances in *private* subnets to initiate outbound connections to the internet (e.g., for updates) without receiving inbound connections, an Egress-Only Internet Gateway would typically be used. This demo uses public IPv6-only subnets with a standard IGW for simplicity.
*   **DNS64 and NAT64 (Not Used Here):** For IPv6-only workloads that need to communicate with IPv4-only services on the internet, DNS64 (on the VPC resolver) and NAT64 (via a NAT Gateway or other device) would be necessary. This demo does not implement NAT64/DNS64.

## Highlights

*   **IPv6-Only Subnets:** Demonstrates the creation and use of subnets where instances operate exclusively with IPv6 addresses for network communication.
*   **Exclusive IPv6 Accessibility:** Instances are reachable from the internet only via their public IPv6 addresses. There are no public IPv4 addresses assigned to these web servers.
*   **Dual-Stack VPC Context:** Clarifies that while the application subnets are IPv6-only, the parent VPC can still support dual-stack operations for other resources.
*   **IPv6-Focused Security:** Security Groups and Network ACLs are tailored to manage IPv6 traffic specifically.

## Key Configuration Variables

*   `aws_region`: The AWS region for deployment (e.g., "us-east-1").
*   `az_list`: A list of two Availability Zones for the public IPv6-only subnets.
*   `cidr_vpc`: The IPv4 CIDR block for the VPC (the VPC itself is dual-stack).
*   `authorized_ips_v6`: A list of IPv6 CIDR blocks allowed for SSH and HTTP access (e.g., `["::/0"]` to allow all IPv6, or your specific IPv6 prefix).
*   `inst_type`: EC2 instance type (e.g., "t2.micro", must support IPv6).
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
    Confirm by typing `yes`. Terraform will output the public IPv6 addresses of the EC2 instances.

## Testing Connectivity

After successful deployment:

1.  **Note EC2 Instance IPv6 Addresses:**
    Get the `Instance1_IPv6_Address` and `Instance2_IPv6_Address` from the Terraform output.

2.  **Test IPv6 HTTP Access:**
    *   This requires your local machine or testing environment to have IPv6 connectivity.
    *   Open a web browser or use `curl` (with appropriate flags for IPv6) to access each instance via its public IPv6 address:
        ```bash
        # For curl, use -g to disable globbing and -6 to force IPv6
        # The IPv6 address should be enclosed in square brackets in the URL for HTTP
        curl -g -6 "http://[<Instance1_IPv6_Address>]"
        curl -g -6 "http://[<Instance2_IPv6_Address>]"
        ```
    *   You should see the test page displaying the hostname of the respective instance. **Access via IPv4 will not be possible as no public IPv4 addresses are assigned to these web servers.**

3.  **Test IPv6 SSH Access:**
    *   Ensure your local machine's IPv6 address is included in `var.authorized_ips_v6`.
    *   This also requires your local machine or testing environment to have IPv6 connectivity.
        ```bash
        ssh -i /path/to/your/ssh-key.pem ec2-user@<Instance1_IPv6_Address>
        ```
    *   You should be able to connect via SSH using the instance's IPv6 address.

Successful access exclusively via IPv6 addresses confirms the IPv6-only subnet configuration is working correctly. Any attempts to reach these specific instances over IPv4 from the internet will fail.
