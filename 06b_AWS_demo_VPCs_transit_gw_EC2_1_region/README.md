# Terraform AWS: Multi-VPC Architecture with Transit Gateway (Single Region)

This Terraform project demonstrates a scalable multi-VPC architecture interconnected by a central AWS Transit Gateway (TGW) within a single AWS region. It typically provisions three VPCs (though configurable), each with its own EC2 instance, showcasing how TGW simplifies network management and connectivity in more complex cloud environments.

## Key Concepts and Features

*   **AWS Transit Gateway (TGW):** Acts as a network hub, connecting multiple VPCs and on-premises networks through a central point. This significantly simplifies routing and reduces the complexity of managing numerous VPC peering connections in a "mesh" topology.
*   **Hub-and-Spoke Model:** VPCs (spokes) connect to the central TGW (hub), enabling inter-VPC communication without direct peering between spoke VPCs.
*   **Scalable Inter-VPC Communication:** Easily add or remove VPCs from the network by managing their attachment to the TGW.
*   **Dedicated TGW Subnets:** Each VPC utilizes a private subnet specifically for its TGW attachment, isolating TGW traffic within the VPC.
*   **Direct Internet Access (DIA):** EC2 instances within each VPC's public subnet have direct internet access via their respective Internet Gateways (IGWs), independent of the TGW. This is suitable for workloads requiring direct outbound and inbound internet connectivity.
*   **Centralized Routing Control (Optional):** While this demo focuses on inter-VPC traffic and DIA, TGW can also centralize outbound traffic through a shared services VPC (not implemented here).

## AWS Resources Provisioned

*   **Multiple VPCs (e.g., 3):**
    *   Controlled by the `var.cidrs_vpc` list. Each VPC is created with a distinct CIDR block.
    *   For each VPC:
        *   **Private TGW Subnet:** A dedicated private subnet (from `var.cidrs_subnet_tgw`) used exclusively for the Transit Gateway attachment. This subnet typically does not contain other resources.
        *   **Public EC2 Subnet:** A public subnet (from `var.cidrs_subnet_ec2`) that hosts an EC2 instance.
        *   **Internet Gateway (IGW):** Each VPC has its own IGW attached, enabling direct internet access for resources in its public subnet.
*   **AWS Transit Gateway (TGW):**
    *   A single TGW is created within the specified region.
    *   It acts as the central router for inter-VPC traffic.
*   **TGW Attachments:**
    *   Each VPC is attached to the TGW via a TGW attachment created in its dedicated private TGW subnet.
*   **Routing Configuration:**
    *   **EC2 Subnet Route Tables (Custom):**
        *   Associated with each public EC2 subnet.
        *   Contains routes for the CIDR blocks of **all other VPCs** in the configuration, with the TGW as the target. This enables instances to reach instances in other VPCs.
        *   Includes a default route (`0.0.0.0/0`) pointing to the local VPC's Internet Gateway (IGW) for direct internet access.
    *   **VPC Default Route Tables (for TGW Subnets):**
        *   These are the main route tables for each VPC. The private TGW subnets use these by default.
        *   A default route (`0.0.0.0/0`) is added to these route tables, pointing all traffic from the TGW subnets (and thus from the TGW attachments within those subnets) towards the Transit Gateway itself. This ensures that traffic entering a VPC from the TGW can be routed appropriately by the TGW to other VPCs.
*   **EC2 Instances:**
    *   One EC2 instance (e.g., Amazon Linux 2023 ARM64, controlled by `var.inst_type`) is launched in the public subnet of each VPC.
    *   Each instance is associated with an **Elastic IP (EIP)** for a stable public IP address.
    *   A single SSH key pair (`var.ssh_key_name`) is typically used for SSH access to all instances.
*   **Network ACLs (NACLs):**
    *   **TGW Subnet NACLs (Default):** Usually kept permissive (allowing all inbound and outbound traffic) as fine-grained control is often managed by Security Groups and TGW route tables.
    *   **EC2 Subnet NACLs (Custom/Default):** Configured to allow inbound SSH (TCP port 22) from `authorized_ips`, necessary OS update traffic (HTTP/HTTPS outbound), and all traffic to/from the CIDR blocks of all configured VPCs to facilitate inter-VPC communication.
*   **Security Groups:**
    *   **EC2 Instance Security Group:** Each EC2 instance has a security group that allows:
        *   Inbound SSH (TCP port 22) from `authorized_ips`.
        *   All inbound traffic (all protocols, all ports) from the CIDR blocks of all configured VPCs (defined in `var.cidrs_vpc`). This permits instances in different VPCs to communicate freely with each other via the TGW.

## Architecture: Hub-and-Spoke with Transit Gateway

This project implements a classic hub-and-spoke network topology:

```
                                 [ AWS Cloud - Single Region ]
                                          |
                               +---------------------+
                               | AWS Transit Gateway | (Hub)
                               | (TGW)               |
                               +---------------------+
                                  /    |      \
                                 /     |       \  (TGW Attachments)
                                /      |        \
           +---------------------+  +---------------------+  +---------------------+
           |        VPC 1        |  |        VPC 2        |  |        VPC 3        | (Spokes)
           | (cidrs_vpc[0])      |  | (cidrs_vpc[1])      |  | (cidrs_vpc[2])      |
           |---------------------|  |---------------------|  |---------------------|
           | [TGW Subnet (Private)]|  | [TGW Subnet (Private)]|  | [TGW Subnet (Private)]|
           |                     |  |                     |  |                     |
           | [Public EC2 Subnet] |  | [Public EC2 Subnet] |  | [Public EC2 Subnet] |
           |   - EC2 Instance 1  |  |   - EC2 Instance 2  |  |   - EC2 Instance 3  |
           |   - EIP             |  |   - EIP             |  |   - EIP             |
           |   - IGW 1           |  |   - IGW 2           |  |   - IGW 3           |
           +--------|------------+  +--------|------------+  +--------|------------+
                    | (Internet)              | (Internet)              | (Internet)
```

- **Hub:** The AWS Transit Gateway.
- **Spokes:** Each of the provisioned VPCs.
- **Communication:**
    - **Inter-VPC:** EC2 Instance 1 can communicate with EC2 Instance 2 (and 3) using their private IP addresses. Traffic flows from EC2-1 -> VPC1's TGW Attachment -> TGW -> VPC2's TGW Attachment -> EC2-2.
    - **Internet:** Each EC2 instance can access the internet directly via its local VPC's IGW.

## Key Configuration Variables

*   `aws_region`: The AWS region for resource deployment (e.g., "us-east-1").
*   `az`: The primary Availability Zone used for subnets (can be expanded for multi-AZ subnets per VPC if desired, but this demo typically uses one AZ per VPC for simplicity).
*   `cidrs_vpc`: A list of distinct CIDR blocks for each VPC to be created (e.g., `["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16"]`).
*   `cidrs_subnet_ec2`: A list of CIDR blocks for the public EC2 subnets, one for each VPC (e.g., `["10.10.1.0/24", "10.20.1.0/24", "10.30.1.0/24"]`).
*   `cidrs_subnet_tgw`: A list of CIDR blocks for the private TGW attachment subnets, one for each VPC (e.g., `["10.10.255.0/28", "10.20.255.0/28", "10.30.255.0/28"]`). These should be small and dedicated.
*   `authorized_ips`: A list of IP addresses or CIDR blocks authorized for SSH access to the EC2 instances (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `inst_type`: The EC2 instance type for all instances (e.g., "t4g.nano" for ARM64).
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

## Testing Transit Gateway Connectivity

After successful deployment:

1.  **SSH into any EC2 Instance (e.g., in VPC1):**
    Use its Elastic IP (EIP) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_Instance_VPC1>
    ```
2.  **Get the Private IP addresses of EC2 instances in the other VPCs (e.g., VPC2 and VPC3):**
    You can find these in the AWS Management Console or from Terraform outputs.
3.  **From the current instance (e.g., in VPC1), ping the private IPs of instances in other VPCs:**
    ```bash
    ping <Private_IP_Instance_VPC2>
    ping <Private_IP_Instance_VPC3>
    ```
    You should see successful ping replies. Repeat this test from instances in other VPCs to confirm bidirectional connectivity.

Successful pings demonstrate that the Transit Gateway is correctly routing traffic between the VPCs using their private IP addresses. You can also test other protocols like SSH or HTTP if your instances and security groups are configured to allow them between VPCs.
