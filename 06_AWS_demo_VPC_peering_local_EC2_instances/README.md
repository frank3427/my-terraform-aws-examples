# AWS VPC Peering Demo

This Terraform project demonstrates VPC peering between two VPCs in the same AWS region with EC2 instances that can communicate with each other.

## Architecture Overview

- **Two VPCs** with separate CIDR blocks in the same region
- **VPC Peering Connection** enabling communication between the VPCs
- **EC2 instances** in each VPC with public IP addresses
- **Cross-VPC connectivity** allowing instances to ping each other using private IPs

## Infrastructure Components

### Network
- **VPC 1**: First VPC with configurable CIDR block and public subnet
- **VPC 2**: Second VPC with configurable CIDR block and public subnet
- **VPC Peering Connection**: Enables communication between both VPCs
- **Internet Gateways**: One for each VPC to provide internet access
- **Route Tables**: Updated to route traffic between peered VPCs

### Compute
- **Instance 1**: EC2 instance in VPC 1 with Elastic IP
- **Instance 2**: EC2 instance in VPC 2 with Elastic IP

### Security
- Security groups allowing SSH access and cross-VPC communication
- Network ACLs configured for authorized IP access and VPC peering traffic

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
   - CIDR blocks for both VPCs and subnets
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
| `03_network1.tf` | First VPC and networking components |
| `04_network2.tf` | Second VPC and networking components |
| `05_data_sources.tf` | AWS data sources |
| `06_ssh_key_pair.tf` | SSH key pair configuration |
| `07_instance1.tf` | EC2 instance in VPC 1 |
| `08_instance2.tf` | EC2 instance in VPC 2 |
| `09_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection commands and testing instructions.

### SSH Access
```bash
# Connect to instance in VPC 1
ssh -i <private_key_path> ec2-user@<instance1_public_ip>

# Connect to instance in VPC 2
ssh -i <private_key_path> ec2-user@<instance2_public_ip>
```

### Testing VPC Peering
Once connected to an instance in one VPC, test connectivity to the other VPC:

```bash
# From instance in VPC 1, ping instance in VPC 2
ping <instance2_private_ip>

# From instance in VPC 2, ping instance in VPC 1
ping <instance1_private_ip>
```

## Security Features

- Instances in separate VPCs with controlled peering
- Security groups allowing only necessary traffic
- Network ACLs with IP-based access restrictions
- Auto-generated SSH key pairs
- Encrypted EBS volumes

## Cloud-Init Scripts

- **Amazon Linux 2**: Installs zsh, nmap, applies updates, and reboots
- **Ubuntu**: Alternative cloud-init script available

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Both instances have Elastic IP addresses for persistent public connectivity
- VPC peering is automatically accepted (same account, same region)
- Route tables are automatically updated to enable cross-VPC communication
- All instances are automatically updated during provisioning