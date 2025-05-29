# Terraform AWS: Local VPC Peering with EC2 Instances

This Terraform project demonstrates how to establish a VPC peering connection between two Virtual Private Clouds (VPCs) located within the same AWS account and region. This setup, often referred to as "local" VPC peering, allows resources in the two VPCs (specifically EC2 instances in this demo) to communicate with each other using their private IP addresses as if they were in the same network.

## Key Concepts and Features

*   **Local VPC Peering:** Enables direct network connectivity between two VPCs in the same AWS account and region. Traffic uses private IP addresses and does not traverse the public internet.
*   **Non-Overlapping CIDRs:** VPC peering requires that the connected VPCs have distinct, non-overlapping CIDR blocks.
*   **Route Table Configuration:** Crucial for enabling traffic flow across the peering connection. Each VPC's route table must be updated to direct traffic destined for the peered VPC's CIDR block to the VPC peering connection.
*   **Security Configuration (NACLs & Security Groups):** Network ACLs and Security Groups in both VPCs must be configured to explicitly allow traffic to and from the peered VPC's CIDR blocks or specific resources.
*   **Auto-Acceptance:** For VPC peering connections within the same AWS account, the peering request can be automatically accepted.

## AWS Resources Provisioned

*   **Two VPCs (VPC1 and VPC2):**
    *   **VPC1:** Created with CIDR block `var.cidr_vpc1`.
        *   Includes an Internet Gateway (IGW1).
        *   A public subnet (Public Subnet 1) with CIDR `var.cidr_public1`.
    *   **VPC2:** Created with CIDR block `var.cidr_vpc2`.
        *   Includes an Internet Gateway (IGW2).
        *   A public subnet (Public Subnet 2) with CIDR `var.cidr_public2`.
*   **VPC Peering Connection:**
    *   An `aws_vpc_peering_connection` resource links VPC1 and VPC2.
    *   `auto_accept = true` is used since both VPCs are in the same account and region.
*   **Route Table Updates:**
    *   **VPC1's Main Route Table:**
        *   A route is added for VPC2's public subnet CIDR (`var.cidr_public2`) pointing to the VPC peering connection.
        *   Retains a default route (`0.0.0.0/0`) to IGW1 for internet access.
    *   **VPC2's Main Route Table:**
        *   A route is added for VPC1's public subnet CIDR (`var.cidr_public1`) pointing to the VPC peering connection.
        *   Retains a default route (`0.0.0.0/0`) to IGW2 for internet access.
*   **EC2 Instances:**
    *   **Instance 1 (in VPC1):** An Amazon Linux 2 ARM64 instance launched in Public Subnet 1.
        *   Associated with an Elastic IP (EIP1).
    *   **Instance 2 (in VPC2):** An Amazon Linux 2 ARM64 instance launched in Public Subnet 2.
        *   Associated with an Elastic IP (EIP2).
    *   A single SSH key pair (`var.ssh_key_name`) is used for SSH access to both instances.
*   **Network ACLs (NACLs):**
    *   **VPC1 Default NACL:** Configured to allow inbound and outbound SSH (TCP port 22) from `authorized_ips` and all traffic to/from VPC2's CIDR block (`var.cidr_vpc2`).
    *   **VPC2 Default NACL:** Configured to allow inbound and outbound SSH (TCP port 22) from `authorized_ips` and all traffic to/from VPC1's CIDR block (`var.cidr_vpc1`).
*   **Security Groups:**
    *   **Instance 1 Security Group (VPC1):** Allows inbound SSH (TCP port 22) from `authorized_ips` and all inbound traffic from VPC2's public subnet CIDR (`var.cidr_public2`).
    *   **Instance 2 Security Group (VPC2):** Allows inbound SSH (TCP port 22) from `authorized_ips` and all inbound traffic from VPC1's public subnet CIDR (`var.cidr_public1`).

## Architecture

The setup consists of two distinct VPCs, VPC1 and VPC2, each with its own public subnet and an EC2 instance. A VPC peering connection directly links these two VPCs.

```
                                [ AWS Cloud ]
                                     |
                   -------------------------------------
                  |                                     |
      (authorized_ips)                         (authorized_ips)
          SSH |                                      SSH |
              ▼                                          ▼
  +-----------------------+      Peering      +-----------------------+
  |         VPC1          |    Connection     |         VPC2          |
  | (var.cidr_vpc1)       |<----------------->| (var.cidr_vpc2)       |
  |                       |                   |                       |
  | +-------------------+ |                   | +-------------------+ |
  | | Public Subnet 1   | |                   | | Public Subnet 2   | |
  | | (var.cidr_public1)| |                   | | (var.cidr_public2)| |
  | |                   | |                   | |                   | |
  | |  [EC2 Instance 1] |<---- Private IP ---->|  [EC2 Instance 2] | |
  | |  (EIP1)           | |    Communication  |  (EIP2)           | |
  | +-------------------+ |                   | +-------------------+ |
  |         |             |                   |         |             |
  |         ▼             |                   |         ▼             |
  |      [IGW1]           |                   |      [IGW2]           |
  +-----------------------+                   +-----------------------+
          To Internet                                To Internet
```

Communication between EC2 Instance 1 and EC2 Instance 2 occurs over their private IP addresses, facilitated by the VPC peering connection and the configured routes, security groups, and NACLs.

## Key Configuration Variables

*   `aws_region`: The AWS region for resource deployment (e.g., "us-east-1").
*   `az`: The Availability Zone used for the public subnets in both VPCs (e.g., "us-east-1a").
*   `cidr_vpc1`: CIDR block for VPC1 (e.g., "10.100.0.0/16").
*   `cidr_public1`: CIDR block for the public subnet in VPC1 (e.g., "10.100.1.0/24").
*   `cidr_vpc2`: CIDR block for VPC2 (e.g., "10.200.0.0/16"). Ensure this does not overlap with `cidr_vpc1`.
*   `cidr_public2`: CIDR block for the public subnet in VPC2 (e.g., "10.200.1.0/24").
*   `authorized_ips`: A list of IP addresses or CIDR blocks authorized for SSH access to the EC2 instances (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `inst_type`: The EC2 instance type for both instances (e.g., "t4g.nano" for ARM64).
*   `ssh_key_name`: The name of an existing EC2 Key Pair for SSH access.
*   `cloud_init_script_path`: Path to the cloud-init script for EC2 instance setup (optional).

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

## Testing Peering Connectivity

After successful deployment:

1.  **SSH into EC2 Instance 1 (in VPC1):**
    Use its Elastic IP (EIP1) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_Instance1>
    ```
2.  **Get the Private IP of EC2 Instance 2 (in VPC2):**
    You can find this in the AWS Management Console or from Terraform outputs.
3.  **From Instance 1, ping the private IP of Instance 2:**
    ```bash
    ping <Private_IP_Instance2>
    ```
    You should see successful ping replies, confirming that traffic is flowing across the VPC peering connection.

4.  **SSH into EC2 Instance 2 (in VPC2):**
    Use its Elastic IP (EIP2) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_Instance2>
    ```
5.  **Get the Private IP of EC2 Instance 1 (in VPC1).**
6.  **From Instance 2, ping the private IP of Instance 1:**
    ```bash
    ping <Private_IP_Instance1>
    ```
    This should also succeed.

Successful pings in both directions confirm that the VPC peering connection, route tables, security groups, and NACLs are correctly configured to allow bidirectional communication between the instances in the peered VPCs.
