# Terraform AWS: EC2 Virtual IP (VIP) with ENI for High Availability

This Terraform project demonstrates a basic Virtual IP (VIP) address setup using an AWS Elastic Network Interface (ENI). The ENI, with an associated Elastic IP (EIP), can be moved between two EC2 instances, providing a simple mechanism for achieving high availability for services hosted on these instances.

## Project Overview

The core idea is to have a static private IP address (the VIP) assigned to a dedicated ENI. This ENI also has a static public IP address (via an EIP) associated with it. This ENI can then be attached as a secondary network interface to one of two EC2 instances (a primary instance). If the primary instance fails, the ENI can be detached and re-attached to a standby instance, effectively transferring the VIP (both private and public) to the standby instance, which then takes over serving traffic.

**Important Note:** This Terraform configuration sets up the initial attachment of the VIP's ENI. The actual **failover mechanism** (detecting failure of the primary instance, detaching the ENI, and re-attaching it to the standby instance) is **NOT** part of this Terraform code. Failover would typically be managed by external scripts (e.g., using AWS CLI/SDK) or clustering software (like Keepalived, Pacemaker).

## Key Features & Concepts

*   **Virtual IP (VIP):** A static IP address that can be moved between different servers. In this AWS context:
    *   The **private VIP** is a specific private IP address assigned to an ENI.
    *   The **public VIP** is an Elastic IP (EIP) associated with that same ENI.
*   **Elastic Network Interface (ENI):** A virtual network interface that can be attached to and detached from EC2 instances in the same Availability Zone. It can retain its private IP address, MAC address, and security group memberships across attachments.
*   **High Availability (Basic):** This setup provides a foundation for HA. If the instance holding the VIP ENI fails, the ENI can be moved to a healthy instance, which then starts serving traffic sent to the VIP.
*   **Manual/Scripted Failover:** This project only defines the resources and their initial state. Failover logic is external.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with a single public subnet and an Internet Gateway (IGW).
*   **EC2 Web Server Instances (x2):**
    *   Launched in the public subnet.
    *   Each instance receives a distinct primary private IP address from the `var.websrv_private_ips` list.
    *   Associated with the `demo19-sg-websrv` security group.
*   **Bastion Host:**
    *   A separate EC2 instance in the public subnet for secure SSH access to the web server instances.
*   **Virtual IP (VIP) Components:**
    *   **Elastic Network Interface (ENI - `aws_network_interface.demo19_vip`):**
        *   Created in the public subnet.
        *   Assigned a specific **private IP address** defined by `var.websrv_private_ip_vip`. This is the private component of the VIP.
        *   Associated with its own dedicated security group (`aws_security_group.demo19_sg_vip`).
        *   Initially attached as a secondary network interface (e.g., `device_index = 1`) to one of the web server instances. The instance that initially owns the VIP ENI is determined by the `var.websrv_vip_owner` variable (e.g., "websrv1" or "websrv2").
    *   **Elastic IP (EIP - `aws_eip.demo19_vip`):**
        *   Associated with the `aws_network_interface.demo19_vip`. This EIP serves as the **public component of the VIP**. Traffic sent to this EIP will be directed to the ENI, and thus to the EC2 instance currently holding the ENI.
*   **Security Groups:**
    *   **Web Server Security Group (`demo19-sg-websrv`):**
        *   Allows inbound HTTP (TCP port 80) from within the VPC.
        *   Allows inbound SSH (TCP port 22) from the Bastion Host's security group.
    *   **VIP ENI Security Group (`aws_security_group.demo19_sg_vip`):**
        *   Allows inbound HTTP (TCP port 80) from `authorized_ips` (or `0.0.0.0/0` if intended for public access to the VIP). This group directly controls access to the service hosted on the VIP.
    *   **Bastion Security Group:** Allows inbound SSH (TCP port 22) from `authorized_ips`.

## Architecture

```
        [ AWS Cloud - Region: var.aws_region ]
                         |
        +---------------------------------------------------+
        |                       VPC                       |
        |                (var.cidr_vpc)                   |
        |                                                 |
        |  +-------------------------------------------+  |
        |  |           Public Subnet                   |  |
        |  |         (var.cidr_subnet1)                |  |
        |  |                                           |  |
        |  |  +-------------------+  +-------------------+  |  +-----------------+
        |  |  | EC2 Web Server 1  |  | EC2 Web Server 2  |  |  | Bastion Host  |
        |  |  | (Primary IP 1)    |  | (Primary IP 2)    |  |  | (SG: BastionSG) |
        |  |  | (SG: demo19-sg-websrv)|  | (SG: demo19-sg-websrv)|  |  +-------+-------+
        |  |  +--------+----------+  +-------------------+  |          | (SSH)
        |  |           |                                   |  |          ▼
        |  |  +--------▼----------+  (ENI initially attached to one server, e.g., Web Server 1)
        |  |  | ENI (demo19_vip)  |<---------------- EIP (demo19_vip) (Public VIP)
        |  |  | - Private VIP     |
        |  |  | - SG: demo19_sg_vip|
        |  |  +-------------------+
        |  |                                           |  |
        |  +-------------------------------------------+  |
        |                      |                          |
        |                      ▼                          |
        |             [Internet Gateway]                  |
        +---------------------------------------------------+
                              | (HTTP to Public VIP)
                           (Internet)
```
Initially, the VIP ENI (with its associated EIP) is attached to one of the web servers (e.g., Web Server 1). Traffic to the public EIP (the VIP) is routed to this server. If Web Server 1 fails, the ENI would need to be manually or programmatically detached and attached to Web Server 2.

## Key Configuration Variables

*   `aws_region`: AWS region for deployment.
*   `az`: Availability Zone for all resources.
*   `cidr_vpc`, `cidr_subnet1`: CIDR blocks for VPC and subnet.
*   `authorized_ips`: IPs/CIDRs for SSH access to bastion and HTTP access to VIP.
*   **`websrv_private_ips`**: A list of two private IP addresses that will be assigned as primary IPs to the two web server instances.
*   **`websrv_private_ip_vip`**: The specific private IP address to be assigned to the VIP ENI. This IP must be within the subnet's CIDR range and should not conflict with other instance primary IPs.
*   **`websrv_vip_owner`**: A string (e.g., "websrv1" or "websrv2") indicating which web server EC2 instance will initially have the VIP ENI attached.
*   Instance types and SSH key names for web servers and bastion.

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

## Failover Considerations

This Terraform setup only defines the initial state of the infrastructure, including the initial attachment of the VIP ENI to one of the instances (`var.websrv_vip_owner`).

**Terraform does not implement the failover logic.**

To achieve automatic or manual failover:
1.  **Health Monitoring:** You need a mechanism to monitor the health of the EC2 instance currently holding the VIP ENI. This could be CloudWatch Alarms, custom health checks, or logic within clustering software.
2.  **ENI Detachment:** If the primary instance is detected as unhealthy, a script or process must:
    *   Use the AWS CLI or SDK to detach the VIP ENI (`aws_network_interface.demo19_vip`) from the failed instance.
    *   Command: `aws ec2 detach-network-interface --attachment-id <eni-attachment-id>`
3.  **ENI Re-attachment:** The script or process must then:
    *   Attach the same VIP ENI to the standby EC2 instance.
    *   Command: `aws ec2 attach-network-interface --network-interface-id <eni-id> --instance-id <standby-instance-id> --device-index 1` (or other available device index).
4.  **OS Configuration (Potentially):** The operating system on the new instance might need to be configured to recognize and use the secondary IP address on the newly attached ENI. Modern AMIs often handle this automatically, but it's a point to verify.
5.  **ARP/MAC Caching:** In some network scenarios, surrounding devices might cache the old MAC address associated with the VIP. Moving an ENI effectively moves the MAC address too, which usually resolves this. However, forceful ARP cache updates or gratuitous ARP might be needed in complex or non-AWS environments.

Tools like **Keepalived** or **Pacemaker** can be configured on the EC2 instances to manage this failover process, or custom scripts using the AWS SDK/CLI can be developed.

**Testing VIP Access:**
After deployment, you can access the service via the public EIP (`aws_eip.demo19_vip`). If you were to manually detach and re-attach the ENI to the other EC2 instance (and ensure the web service is running there), you would see traffic seamlessly redirected to the new instance via the same EIP.
