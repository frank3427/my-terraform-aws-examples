# Terraform AWS: Cross-Region VPC Peering with EC2 Instances

This Terraform project demonstrates how to establish a VPC peering connection between two Virtual Private Clouds (VPCs) located in **different AWS regions**. This setup, known as cross-region VPC peering, allows resources (specifically EC2 instances in this demo) in the two VPCs to communicate with each other using their private IP addresses as if they were in the same network, despite being geographically distant.

The principles shown here can also be adapted for **cross-account VPC peering** with minor modifications to provider configurations and the peering acceptance mechanism.

## Key Concepts and Features

*   **Cross-Region VPC Peering:** Enables direct network connectivity between two VPCs in different AWS regions within the same AWS account (as demonstrated) or different accounts. Traffic uses private IP addresses and traverses the AWS global backbone, not the public internet.
*   **Multiple AWS Providers:** Terraform uses provider aliases to manage resources in different AWS regions simultaneously.
*   **`peer_region` Argument:** The `aws_vpc_peering_connection` resource in the requester region must specify the `peer_region` where the accepter VPC resides.
*   **Requester and Accepter Model:**
    *   One VPC initiates the peering request (Requester).
    *   The other VPC accepts the request (Accepter). This is crucial for cross-region and cross-account scenarios.
*   **Non-Overlapping CIDRs:** VPC peering requires that the connected VPCs have distinct, non-overlapping CIDR blocks.
*   **Route Table Configuration:** Essential for enabling traffic flow. Each VPC's route table must be updated to direct traffic destined for the peered VPC's CIDR block to the VPC peering connection.
*   **Security Configuration (NACLs & Security Groups):** Network ACLs and Security Groups in both VPCs must be configured to explicitly allow traffic to and from the peered VPC's CIDR blocks.

## AWS Resources Provisioned

*   **Two AWS Providers:**
    *   Provider 1: Configured for `var.aws_region1`.
    *   Provider 2: Configured for `var.aws_region2` (using an alias, e.g., `aws.accepter_region`).
*   **Two VPCs (VPC1 in Region 1, VPC2 in Region 2):**
    *   **VPC1 (Region 1):**
        *   Created with CIDR block `var.cidr_vpc_r1` using Provider 1.
        *   Includes an Internet Gateway (IGW1).
        *   A public subnet (Public Subnet R1) with CIDR `var.cidr_public_r1`.
    *   **VPC2 (Region 2):**
        *   Created with CIDR block `var.cidr_vpc_r2` using Provider 2.
        *   Includes an Internet Gateway (IGW2).
        *   A public subnet (Public Subnet R2) with CIDR `var.cidr_public_r2`.
*   **Cross-Region VPC Peering Connection:**
    *   **Requester Side (Region 1):**
        *   An `aws_vpc_peering_connection` resource is created in Region 1.
        *   It specifies `vpc_id = VPC1.id`, `peer_vpc_id = VPC2.id`, and crucially, `peer_region = var.aws_region2`.
        *   `auto_accept` is typically set to `false` or omitted for cross-region/cross-account peering, as acceptance is handled by the accepter region/account.
    *   **Accepter Side (Region 2):**
        *   An `aws_vpc_peering_connection_accepter` resource is created in Region 2 using Provider 2.
        *   It references the `vpc_peering_connection_id` of the connection initiated in Region 1.
        *   `auto_accept = true` is used here because this demo assumes the same AWS account owns both VPCs. For cross-account peering, this would be `false`, and acceptance would need to be done manually in the accepter account's console or via an API call by an IAM principal with permissions in the accepter account.
*   **Route Table Updates:**
    *   **VPC1's Route Table (Region 1):**
        *   A route is added for VPC2's public subnet CIDR (`var.cidr_public_r2`) pointing to the VPC peering connection.
        *   Retains a default route (`0.0.0.0/0`) to IGW1 for local internet access.
    *   **VPC2's Route Table (Region 2):**
        *   A route is added for VPC1's public subnet CIDR (`var.cidr_public_r1`) pointing to the VPC peering connection.
        *   Retains a default route (`0.0.0.0/0`) to IGW2 for local internet access.
*   **EC2 Instances:**
    *   **Instance R1 (in VPC1, Region 1):** An EC2 instance launched in Public Subnet R1.
        *   Associated with an Elastic IP (EIP_R1).
        *   Uses an SSH key pair specific to Region 1.
    *   **Instance R2 (in VPC2, Region 2):** An EC2 instance launched in Public Subnet R2.
        *   Associated with an Elastic IP (EIP_R2).
        *   Uses an SSH key pair specific to Region 2.
*   **Network ACLs (NACLs) and Security Groups (SGs):**
    *   Configured in each VPC to allow inbound SSH (TCP port 22) from `authorized_ips`.
    *   Configured to allow all inbound/outbound traffic to/from the peered VPC's public subnet CIDR to facilitate communication over the peering connection.

## Architecture: Cross-Region VPC Peering

```
     [ AWS Region 1: var.aws_region1 ]        AWS Global Backbone        [ AWS Region 2: var.aws_region2 ]
     +---------------------------------+      <-------------------->      +---------------------------------+
     |             VPC 1             |<----VPC Peering Connection---->|             VPC 2             |
     |      (var.cidr_vpc_r1)        |                                |      (var.cidr_vpc_r2)        |
     |                               |                                |                               |
     |  +-------------------------+  |                                |  +-------------------------+  |
     |  | Public Subnet R1        |  |                                |  | Public Subnet R2        |  |
     |  | (var.cidr_public_r1)    |  |                                |  | (var.cidr_public_r2)    |  |
     |  |                         |  |                                |  |                         |  |
     |  |  [EC2 Instance R1]      |<------ Private IP Comm ------>|  [EC2 Instance R2]      |  |
     |  |  (EIP_R1, SSH Key R1)   |  |                                |  |  (EIP_R2, SSH Key R2)   |  |
     |  +-------------------------+  |                                |  +-------------------------+  |
     |              |                |                                |              |                |
     |              ▼                |                                |              ▼                |
     |           [IGW1]              |                                |           [IGW2]              |
     +---------------------------------+                                +---------------------------------+
        (Internet Access for R1)                                          (Internet Access for R2)
```
Traffic between EC2 Instance R1 and EC2 Instance R2 uses their private IP addresses and is routed over the AWS global network infrastructure, not the public internet.

## Considerations for Cross-Account Peering

If adapting this for cross-account peering:
1.  The `aws_vpc_peering_connection` in the requester account would specify the `peer_owner_id` (the AWS Account ID of the accepter).
2.  The `aws_vpc_peering_connection_accepter` resource in the accepter account (Region 2) would be run by Terraform using credentials for the accepter account. `auto_accept` would likely be `true` in this context if the Terraform principal has accept permissions.
3.  Alternatively, if `auto_accept = false` on the accepter resource, or if not using Terraform for acceptance, the peering request must be manually accepted in the accepter account's VPC console or via an API call. The requester might also need to configure the accepter options using `aws_vpc_peering_connection_options` if DNS resolution is required.

## Key Configuration Variables

*   `aws_region1`: The AWS region for VPC1 (e.g., "us-east-1").
*   `aws_region2`: The AWS region for VPC2 (e.g., "eu-west-2").
*   `cidr_vpc_r1`: CIDR block for VPC1 in Region 1 (e.g., "10.100.0.0/16").
*   `cidr_public_r1`: CIDR block for the public subnet in VPC1 (e.g., "10.100.1.0/24").
*   `cidr_vpc_r2`: CIDR block for VPC2 in Region 2 (e.g., "10.200.0.0/16"). Ensure non-overlapping.
*   `cidr_public_r2`: CIDR block for the public subnet in VPC2 (e.g., "10.200.1.0/24").
*   `authorized_ips`: List of IPs/CIDRs for SSH access to EC2 instances (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `az`: Availability Zone letter (e.g., "a"). The actual AZ will be `var.aws_region1` + `var.az` or `var.aws_region2` + `var.az`.
*   `inst_type`: EC2 instance type (e.g., "t3.micro").
*   `ssh_key_name_r1`: Name of an existing EC2 Key Pair in Region 1.
*   `ssh_key_name_r2`: Name of an existing EC2 Key Pair in Region 2.
*   `cloud_init_script_path`: Path to EC2 cloud-init script (optional, may need region-specific logic if used).

## Usage

1.  **Configure Providers:** Ensure your Terraform configuration correctly defines two AWS providers with aliases, one for each region.
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

## Testing Peering Connectivity

After successful deployment:

1.  **SSH into EC2 Instance R1 (in VPC1, Region 1):**
    Use its Elastic IP (EIP_R1) and the SSH key for Region 1.
2.  **Get the Private IP of EC2 Instance R2 (in VPC2, Region 2):**
    Find this in the AWS Management Console for Region 2 or from Terraform outputs.
3.  **From Instance R1, ping the private IP of Instance R2:**
    ```bash
    ping <Private_IP_InstanceR2>
    ```
    You should see successful ping replies.

4.  **SSH into EC2 Instance R2 (in VPC2, Region 2):**
    Use its Elastic IP (EIP_R2) and the SSH key for Region 2.
5.  **Get the Private IP of EC2 Instance R1 (in VPC1, Region 1).**
6.  **From Instance R2, ping the private IP of Instance R1:**
    ```bash
    ping <Private_IP_InstanceR1>
    ```
    This should also succeed.

Successful pings confirm that the cross-region VPC peering is active and correctly configured.
