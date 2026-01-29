# AWS Transit Gateway Demo - Single Region

This Terraform project demonstrates AWS Transit Gateway connectivity between multiple VPCs in the same region with EC2 instances that can communicate across all VPCs.

## Architecture Overview

- **Three VPCs** with separate CIDR blocks in the same region
- **Transit Gateway** enabling centralized connectivity between all VPCs
- **EC2 instances** in each VPC with public IP addresses
- **Full mesh connectivity** allowing instances to communicate across all VPCs

## Infrastructure Components

### Network
- **Three VPCs**: Each with configurable CIDR blocks
- **Transit Gateway**: Central hub for inter-VPC communication
- **Public subnets**: For EC2 instances with internet access
- **Private subnets**: For Transit Gateway attachments
- **Internet Gateways**: One for each VPC
- **Route Tables**: Configured for Transit Gateway routing

### Compute
- **EC2 Instances**: One instance per VPC with Elastic IP addresses
- **Amazon Linux 2023**: Latest AMI with ARM64 architecture

### Security
- Security groups allowing SSH access and cross-VPC communication
- Network ACLs configured for authorized IP access and inter-VPC traffic

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
| `03_network.tf` | VPCs, Transit Gateway, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_instances.tf` | EC2 instances in all VPCs |
| `07_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection commands and testing instructions.

### SSH Access
```bash
# Connect to instance in VPC 1
ssh -i <private_key_path> ec2-user@<instance1_public_ip>

# Connect to instance in VPC 2
ssh -i <private_key_path> ec2-user@<instance2_public_ip>

# Connect to instance in VPC 3
ssh -i <private_key_path> ec2-user@<instance3_public_ip>
```

### Testing Transit Gateway Connectivity
From any instance, test connectivity to instances in other VPCs:

```bash
# From VPC 1, ping instances in VPC 2 and 3
ping <instance2_private_ip>
ping <instance3_private_ip>

# From VPC 2, ping instances in VPC 1 and 3
ping <instance1_private_ip>
ping <instance3_private_ip>

# From VPC 3, ping instances in VPC 1 and 2
ping <instance1_private_ip>
ping <instance2_private_ip>
```

## Security Features

- Instances in separate VPCs with centralized Transit Gateway routing
- Security groups allowing only necessary traffic
- Network ACLs with IP-based access restrictions
- Auto-generated SSH key pairs
- Encrypted EBS volumes

## Cloud-Init Scripts

- **Amazon Linux 2023**: Installs packages, applies updates, and reboots

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- All instances have Elastic IP addresses for persistent public connectivity
- Transit Gateway provides full mesh connectivity between all VPCs
- Route tables are automatically configured for inter-VPC communication
- All instances are automatically updated during provisioning
- Uses ARM64 architecture for cost optimization