# AWS Transit Gateway Demo - Shared Services Architecture

This Terraform project demonstrates AWS Transit Gateway with a shared services architecture where VPC 1 acts as a hub for shared services, with selective routing between VPCs.

## Architecture Overview

- **Three VPCs** with separate CIDR blocks in the same region
- **Transit Gateway** with custom route tables for selective connectivity
- **Shared Services VPC** (VPC 1) accessible from both other VPCs
- **Selective routing** preventing direct communication between VPC 2 and VPC 3
- **EC2 instances** in each VPC with public IP addresses

## Infrastructure Components

### Network
- **VPC 1**: Shared services VPC with hub connectivity
- **VPC 2**: Spoke VPC with access only to VPC 1
- **VPC 3**: Spoke VPC with access only to VPC 1
- **Transit Gateway**: Central hub with custom route tables
- **Custom Route Tables**: Implementing selective routing policies
- **Public subnets**: For EC2 instances with internet access
- **Private subnets**: For Transit Gateway attachments

### Routing Architecture
- **VPC 1 ↔ VPC 2**: Bidirectional communication enabled
- **VPC 1 ↔ VPC 3**: Bidirectional communication enabled
- **VPC 2 ↔ VPC 3**: Communication blocked (no direct route)

### Compute
- **EC2 Instances**: One instance per VPC with Elastic IP addresses
- **Amazon Linux 2023**: Latest AMI with ARM64 architecture

### Security
- Security groups allowing SSH access and selective cross-VPC communication
- Network ACLs configured for authorized IP access and controlled inter-VPC traffic

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zone
   - CIDR blocks for VPCs and subnets
   - Authorized IP addresses for SSH access
   - Instance type and SSH key paths

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

## Configuration Files

| File | Purpose |
|------|---------|
| `01_variables.tf` | Variable definitions |
| `02_provider.tf` | AWS provider configuration |
| `03_network.tf` | VPCs, Transit Gateway, and selective routing |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_instances.tf` | EC2 instances in all VPCs |
| `07_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection commands and testing instructions.

### SSH Access
```bash
# Connect to shared services VPC (VPC 1)
ssh -i <private_key_path> ec2-user@<instance1_public_ip>

# Connect to spoke VPC 2
ssh -i <private_key_path> ec2-user@<instance2_public_ip>

# Connect to spoke VPC 3
ssh -i <private_key_path> ec2-user@<instance3_public_ip>
```

### Testing Selective Connectivity
Test the shared services architecture:

```bash
# From VPC 1 (shared services), can reach both VPC 2 and 3
ping <instance2_private_ip>  # Should work
ping <instance3_private_ip>  # Should work

# From VPC 2, can only reach VPC 1 (shared services)
ping <instance1_private_ip>  # Should work
ping <instance3_private_ip>  # Should NOT work (no route)

# From VPC 3, can only reach VPC 1 (shared services)
ping <instance1_private_ip>  # Should work
ping <instance2_private_ip>  # Should NOT work (no route)
```

## Security Features

- Selective routing preventing unwanted inter-VPC communication
- Security groups allowing only necessary traffic
- Network ACLs with IP-based access restrictions
- Auto-generated SSH key pairs
- Encrypted EBS volumes

## Cloud-Init Scripts

- **Amazon Linux 2023**: Installs packages, applies updates, and reboots

## Important Notes

- **Two-run requirement**: Due to Terraform dependencies, this configuration may require running `terraform apply` twice
- Custom Transit Gateway route tables implement the selective routing
- VPC 1 uses a dedicated route table separate from the default

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- All instances have Elastic IP addresses for persistent public connectivity
- Transit Gateway implements hub-and-spoke architecture with VPC 1 as the hub
- Custom route table associations prevent direct VPC 2 ↔ VPC 3 communication
- Uses ARM64 architecture for cost optimization
- Perfect for shared services scenarios like DNS, monitoring, or security services