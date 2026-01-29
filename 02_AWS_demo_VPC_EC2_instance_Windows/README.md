# AWS VPC with Windows EC2 Instance Demo

This Terraform project demonstrates a complete AWS infrastructure setup with VPC and Windows EC2 instance with EBS volume.

## Architecture Overview

- **VPC** with public subnet
- **Windows EC2 instance** with RDP access
- **EBS volume** attached to the instance
- **Security groups** configured for RDP access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for Windows instance
- Internet Gateway for public access

### Compute
- **Windows EC2 Instance**: Windows Server with RDP access enabled

### Storage
- **EBS Volume**: Additional storage attached to the Windows instance

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- RDP client for connecting to Windows instance

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for RDP access
   - Instance types and availability zones

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
| `03_network.tf` | VPC, subnets, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_instance.tf` | Windows EC2 instance configuration |
| `06_ebs_volume.tf` | EBS volume configuration |

## Usage

After deployment, connect to the Windows instance using RDP with the credentials provided in the Terraform output.

### RDP Access
Use the public IP address and administrator credentials to connect via RDP.

## Security Features

- Security groups with RDP access restrictions
- IP-based access control
- Windows firewall configuration

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Windows instance requires time to initialize after deployment
- Administrator password is automatically generated
- EBS volume is automatically attached and formatted