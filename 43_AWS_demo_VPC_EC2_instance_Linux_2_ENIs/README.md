# Terraform AWS: EC2 Instance with Multiple ENIs for Traffic Segmentation

This Terraform project demonstrates how to provision a single Linux EC2 instance (Amazon Linux 2) with **two Elastic Network Interfaces (ENIs)**. Each ENI is placed in a different public subnet and is associated with its own Security Group and public Elastic IP (EIP) address. This setup is a common pattern for achieving network traffic segmentation, such as separating management traffic from application traffic.

## Purpose

The primary goals of this project are to illustrate:
1.  The attachment of multiple ENIs to a single EC2 instance.
2.  How each ENI can reside in a different subnet, allowing for distinct network configurations (e.g., different Network ACLs).
3.  How each ENI can have its own Security Group, enabling fine-grained firewall rules per interface.
4.  How each ENI can have its own public IP address (via EIP).
5.  A practical use case: isolating SSH management traffic on one ENI/IP (`eth0`) and web application traffic (HTTP) on another ENI/IP (`eth1`).

## Key Components

1.  **VPC Infrastructure:**
    *   A new VPC is created.
    *   **Two Public Subnets:**
        *   `public1-ssh` (e.g., `var.cidr_subnet1_public_ssh`): Intended primarily for management traffic (SSH). This subnet is associated with the VPC's default Network ACL, which in this demo is configured to allow SSH.
        *   `public2-http` (e.g., `var.cidr_subnet2_public_http`): Intended primarily for application traffic (HTTP). This subnet is associated with a custom Network ACL (`aws_network_acl.demo43_nacl_public2`) configured to allow HTTP traffic.
    *   An Internet Gateway (IGW) is attached to the VPC.
    *   Route tables for both subnets include a default route to the IGW.
2.  **EC2 Instance (`aws_instance.demo43_inst1`):**
    *   A single Amazon Linux 2 instance is launched.
    *   **Primary Network Interface (`eth0`):**
        *   This ENI is implicitly created when the instance is launched.
        *   It is placed in the first public subnet (`public1-ssh`).
        *   Associated with a Security Group (`aws_security_group.demo43_sg1_ssh`) specifically configured to allow inbound SSH traffic from `authorized_ips`.
        *   An Elastic IP (`aws_eip.demo43_eip1_ssh`) is associated with this ENI, providing a static public IP for SSH access.
    *   **Secondary Network Interface (`eth1` - `aws_network_interface.demo43_inst1_eni2`):**
        *   This ENI is **explicitly created** as an `aws_network_interface` resource.
        *   It is placed in the second public subnet (`public2-http`).
        *   Associated with a separate Security Group (`aws_security_group.demo43_sg2_http`) specifically configured to allow inbound HTTP traffic from `authorized_ips` (or `0.0.0.0/0` for public web access).
        *   It is attached to the EC2 instance using an `aws_network_interface_attachment` resource, with `device_index = 1` (representing `eth1`).
        *   A distinct Elastic IP (`aws_eip.demo43_eip2_http`) is associated with this ENI, providing a static public IP for HTTP access to the web server.
3.  **Cloud-Init Script (`user_data`):**
    *   A simple cloud-init script is provided to the EC2 instance.
    *   It installs Apache (`httpd`) and PHP.
    *   It starts the Apache web server and configures it to serve a basic test page (e.g., displaying the instance's hostname or a simple "Hello World" message). This allows testing HTTP access on the secondary ENI.

## Network Configuration Details

This setup provides network segmentation using multiple ENIs:

*   **Subnet-Level Separation:**
    *   `eth0` resides in `public1-ssh`. Its network environment (including NACL rules applied to `public1-ssh`) is tailored for management.
    *   `eth1` resides in `public2-http`. Its network environment (including NACL rules applied to `public2-http`) is tailored for web traffic.
*   **Security Group Separation:**
    *   `eth0` uses `sg1` (SSH rules).
    *   `eth1` uses `sg2` (HTTP rules).
    This allows for independent firewall policies for management and application traffic.
*   **Public IP Separation:** Each ENI has its own EIP, meaning the instance can be reached on two different public IP addresses, each intended for a different purpose.
*   **Network ACLs:** The use of different NACLs for `public1-ssh` (default NACL, allowing SSH) and `public2-http` (custom NACL `demo43_nacl_public2`, allowing HTTP) provides an additional layer of stateless filtering at the subnet boundary, further segmenting traffic types.

## OS-Level Configuration Note

When an EC2 instance has multiple ENIs, especially if they are in different subnets, the operating system needs to be configured correctly to handle routing for traffic originating from the instance via these interfaces.

*   **Simple Case (This Demo):** For basic inbound traffic to services listening on all interfaces (like Apache on `0.0.0.0:80`), and when each ENI has a default gateway in its respective subnet (common for public subnets), the setup is relatively straightforward. The cloud-init script here simply starts Apache, which will listen on all available IP addresses.
*   **Advanced Scenarios:** For more complex scenarios, such as ensuring that traffic originating *from* the instance for a specific application goes out via a particular ENI (e.g., if `eth1` was in a private subnet with a NAT Gateway route and `eth0` had IGW route), you might need to configure **policy-based routing** or source-based routing within the EC2 instance's operating system. This involves creating custom route tables at the OS level and rules that dictate which route table to use based on the source IP address of the outbound packet. This project's cloud-init does not cover such advanced OS-level routing.

## Highlights

*   **Multiple ENIs on a Single EC2:** Demonstrates the capability of attaching more than one network interface to an EC2 instance.
*   **Traffic Segmentation:** Provides a clear example of how multiple ENIs can be used to separate different types of network traffic (e.g., management on `eth0`/SSH, application on `eth1`/HTTP).
*   **Independent Security Posture:** Each ENI can have its own security group, allowing for tailored firewall rules.
*   **Distinct Public IPs:** Each ENI can be associated with its own Elastic IP address.
*   **Subnet-Specific Configurations:** Each ENI can reside in a different subnet, potentially subject to different Network ACL rules.

## Key Configuration Variables

*   `aws_region`: The AWS region for deployment.
*   `az_list`: A list of two Availability Zones (one for each public subnet).
*   `cidr_vpc`, `cidr_subnet1_public_ssh`, `cidr_subnet2_public_http`: CIDR blocks.
*   `authorized_ips`: List of IPs/CIDRs for SSH (to `eth0`) and HTTP (to `eth1`) access.
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
    Confirm by typing `yes`. Terraform will output the EIPs for both ENIs.

## Testing Connectivity

After successful deployment:

1.  **Note the Elastic IPs:**
    Get `EIP_for_ENI0_SSH` and `EIP_for_ENI1_HTTP` from the Terraform output.

2.  **Test SSH Access (to `eth0`):**
    SSH into the EC2 instance using the EIP associated with the primary ENI (`eth0`).
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_for_ENI0_SSH>
    ```
    You should be able to connect successfully. Inside the instance, you can run `ip addr` to see both `eth0` and `eth1` interfaces with their respective private IP addresses.

3.  **Test HTTP Access (to `eth1`):**
    Open a web browser or use `curl` to access the EC2 instance via the EIP associated with the secondary ENI (`eth1`).
    ```bash
    curl http://<EIP_for_ENI1_HTTP>
    ```
    You should see the test page served by the Apache web server (e.g., displaying the instance's hostname).

This testing confirms that traffic is correctly routed to the appropriate interface based on the destination public IP address and that the security groups for each ENI are functioning as expected.
