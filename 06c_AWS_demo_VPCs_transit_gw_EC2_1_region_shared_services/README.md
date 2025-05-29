# Terraform AWS: Shared Services VPC with Transit Gateway and Custom Routing

This Terraform project demonstrates a "Shared Services" VPC architecture using AWS Transit Gateway (TGW) within a single AWS region. It leverages custom TGW route tables, associations, and propagations to enforce specific traffic flow patterns: a central Shared Services VPC can communicate with multiple Spoke/Workload VPCs, and vice-versa, but the Spoke VPCs are isolated from each other for traffic transiting the TGW. This project typically provisions three VPCs: one Shared Services VPC (VPC-A) and two Spoke VPCs (VPC-B, VPC-C).

## Key Concepts and Features

*   **Shared Services VPC Model:** A common networking pattern where a central VPC (Shared Services VPC) hosts common services (e.g., security appliances, monitoring tools, domain controllers) that are accessed by multiple workload/spoke VPCs.
*   **AWS Transit Gateway (TGW):** Acts as a network hub, connecting the Shared Services VPC and all Spoke VPCs.
*   **Custom TGW Route Tables for Traffic Isolation:**
    *   The key to this architecture is the use of multiple TGW route tables to control how routes are learned and which VPCs can communicate.
    *   **Spoke-to-Hub Communication:** Spoke VPCs learn routes to the Shared Services VPC.
    *   **Hub-to-Spoke Communication:** The Shared Services VPC learns routes to all Spoke VPCs.
    *   **Spoke-to-Spoke Isolation (via TGW):** Spoke VPCs do not learn routes to each other through the TGW, preventing direct inter-spoke communication via the TGW.
*   **Dedicated TGW Subnets:** Each VPC has a private subnet for its TGW attachment.
*   **Direct Internet Access (DIA):** EC2 instances in each VPC's public subnet have direct internet access via their local Internet Gateways (IGWs).

## AWS Resources Provisioned

*   **Multiple VPCs (e.g., 3):**
    *   Controlled by `var.cidrs_vpc`. Default configuration assumes 3 VPCs:
        *   **VPC-A (Index 0):** The Shared Services VPC.
        *   **VPC-B (Index 1), VPC-C (Index 2, etc.):** Spoke/Workload VPCs.
    *   For each VPC:
        *   A distinct CIDR block.
        *   A private TGW attachment subnet (from `var.cidrs_subnet_tgw`).
        *   A public EC2 subnet (from `var.cidrs_subnet_ec2`) with an EC2 instance.
        *   An Internet Gateway (IGW).
*   **AWS Transit Gateway (TGW):**
    *   A single TGW acting as the central network hub.
    *   Each VPC (Shared Services and Spokes) is attached to this TGW via its TGW subnet.
*   **Custom TGW Routing Configuration:**
    *   **Default TGW Route Table (e.g., `tgw-rtb-default`):**
        *   **Association:** Spoke VPCs (VPC-B, VPC-C) are *associated* with this route table. This means traffic originating from Spoke VPCs will use this table for routing decisions by the TGW.
        *   **Propagation:** Only the Shared Services VPC (VPC-A) *propagates* its routes (its VPC CIDR) to this table.
        *   **Result:** Spoke VPCs using this table can only learn routes to VPC-A. They do not see routes to other Spoke VPCs.
    *   **Custom TGW Route Table (e.g., `tgw-rt-shared-services`):**
        *   **Association:** The Shared Services VPC (VPC-A) is *associated* with this route table. Traffic from VPC-A uses this table.
        *   **Propagation:** Spoke VPCs (VPC-B, VPC-C) *propagate* their routes to this table.
        *   **Result:** The Shared Services VPC can learn routes to both VPC-B and VPC-C.
    *   **Overall Intended Routing Behavior:**
        *   VPC-A (Shared Services) **can** communicate with VPC-B and VPC-C.
        *   VPC-B and VPC-C **can** communicate with VPC-A.
        *   VPC-B and VPC-C **cannot** communicate directly with each other via the TGW.
*   **VPC Subnet Routing:**
    *   **EC2 Subnet Route Tables (Custom):**
        *   Associated with each public EC2 subnet in every VPC.
        *   Contains routes for the CIDR blocks of **all other configured VPCs** (both Shared Services and other Spokes), with the TGW as the target. The TGW then makes the final routing decision based on its own isolated route tables.
        *   Includes a default route (`0.0.0.0/0`) pointing to the local VPC's IGW for DIA.
*   **EC2 Instances:**
    *   One EC2 instance (e.g., Amazon Linux 2023 ARM64) in each VPC's public subnet.
    *   Each with an Elastic IP (EIP).
    *   Typically uses a single SSH key pair.
*   **Network ACLs (NACLs) and Security Groups (SGs):**
    *   Configured to allow permitted traffic:
        *   SSH from `authorized_ips` to EC2 instances.
        *   Inter-VPC traffic according to the logic (A <-> B/C), typically by allowing traffic from the respective VPC CIDRs in SGs.

## Architecture: Shared Services with TGW Custom Routing

The architecture establishes a hub (TGW) and spokes (VPC-A, VPC-B, VPC-C), but with controlled communication paths enforced by TGW route tables:

```
                                 [ AWS Cloud - Single Region ]
                                          |
                               +---------------------+
                               | AWS Transit Gateway | (Hub)
                               | (TGW)               |
                               +---------------------+
                                  /    |      \
(TGW Attachments)                /     |       \
                                /      |        \
           +---------------------+  +---------------------+  +---------------------+
           |  VPC-A (Shared Svc) |  |    VPC-B (Spoke)    |  |    VPC-C (Spoke)    |
           |  (cidrs_vpc[0])     |  |  (cidrs_vpc[1])     |  |  (cidrs_vpc[2])     |
           |---------------------|  |---------------------|  |---------------------|
           | [TGW Subnet]        |  | [TGW Subnet]        |  | [TGW Subnet]        |
           | [Public EC2 Subnet] |  | [Public EC2 Subnet] |  | [Public EC2 Subnet] |
           |   - EC2 Inst-A (EIP)|  |   - EC2 Inst-B (EIP)|  |   - EC2 Inst-C (EIP)|
           |   - IGW-A           |  |   - IGW-B           |  |   - IGW-C           |
           +--------|------------+  +--------|------------+  +--------|------------+
                    | (Internet)              | (Internet)              | (Internet)

TGW Routing:
  Default TGW Route Table:
    - Associated VPCs: VPC-B, VPC-C
    - Propagated Routes From: VPC-A
    - Result: VPC-B, VPC-C learn route to VPC-A.

  Custom TGW Route Table ('tgw-rt-shared-services'):
    - Associated VPCs: VPC-A
    - Propagated Routes From: VPC-B, VPC-C
    - Result: VPC-A learns routes to VPC-B, VPC-C.

Traffic Flow:
  - VPC-A <---> VPC-B (via TGW)
  - VPC-A <---> VPC-C (via TGW)
  - VPC-B <-X-> VPC-C (No direct path via TGW)
```

## `PROBLEM_NEED_2_RUNS` - Important Note on Terraform Apply

Due to the way Terraform models dependencies and eventual consistency with AWS Transit Gateway route table associations and propagations, it might be necessary to run `terraform apply` **twice** for the routing to fully converge and reflect the intended state.

1.  **First `terraform apply`:** Creates the TGW, attachments, route tables, and attempts associations/propagations. Some propagations might not take effect if the associated attachment isn't fully ready from Terraform's perspective in the same run.
2.  **Second `terraform apply`:** Re-evaluates the configuration. By this time, attachments are stable, and Terraform can successfully establish any remaining propagations or associations, ensuring the custom routing logic is correctly implemented in the TGW route tables.

This is a known characteristic when dealing with complex TGW routing configurations in Terraform. Always check the TGW route tables in the AWS console after deployment to verify.

## Key Configuration Variables

*   `aws_region`: AWS region (e.g., "us-east-1").
*   `az`: Primary Availability Zone for subnets.
*   `cidrs_vpc`: List of distinct CIDR blocks for each VPC (e.g., `["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16"]`). Index 0 is Shared Services VPC.
*   `cidrs_subnet_ec2`: List of CIDRs for public EC2 subnets, one per VPC.
*   `cidrs_subnet_tgw`: List of CIDRs for private TGW attachment subnets, one per VPC.
*   `authorized_ips`: IPs/CIDRs for SSH access to EC2s.
*   `inst_type`: EC2 instance type (e.g., "t4g.nano").
*   `ssh_key_name`: Name of an existing EC2 Key Pair.
*   `cloud_init_script_path`: Path to EC2 cloud-init script (optional).

## Usage

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    ```bash
    terraform plan
    ```
3.  **Apply Changes (Potentially Twice):**
    ```bash
    terraform apply
    ```
    Review the plan and confirm. If inter-VPC connectivity isn't as expected, run `terraform apply` again.
    ```bash
    terraform apply # Second run if needed
    ```

## Testing Connectivity and Isolation

After deployment (and potentially two `apply` runs):

1.  **SSH into EC2 Instance in VPC-A (Shared Services):**
    *   Ping the private IP of the EC2 instance in VPC-B. **Should succeed.**
    *   Ping the private IP of the EC2 instance in VPC-C. **Should succeed.**

2.  **SSH into EC2 Instance in VPC-B (Spoke):**
    *   Ping the private IP of the EC2 instance in VPC-A. **Should succeed.**
    *   Ping the private IP of the EC2 instance in VPC-C. **Should FAIL.** (Traffic would try to route via TGW, which should not have a route from B to C).

3.  **SSH into EC2 Instance in VPC-C (Spoke):**
    *   Ping the private IP of the EC2 instance in VPC-A. **Should succeed.**
    *   Ping the private IP of the EC2 instance in VPC-B. **Should FAIL.**

Verify these results to confirm the TGW custom routing is isolating spoke-to-spoke traffic while allowing hub-and-spoke communication. Check TGW route tables in the AWS console to further validate.
