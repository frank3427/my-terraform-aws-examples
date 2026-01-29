# AWS VPC with Systems Manager (Private) Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, EC2 instances in private subnets, and AWS Systems Manager with VPC endpoints for secure remote management.

## Architecture Overview

- **VPC** with public and 2 private subnets (1 per AZ)
- **EC2 instances** in private subnets with Systems Manager access
- **VPC endpoints** for Systems Manager communication


## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Private subnets for managed instances
- NAT Gateways for outbound internet access
- VPC endpoints for Systems Manager services

### Compute

- **Managed Instances**: Amazon Linux 2 in private subnet with Systems Manager
- **IAM Role**: Permissions for Systems Manager communication

### Management
- AWS Systems Manager Session Manager for shell access
- VPC endpoints for secure Systems Manager communication
- No direct internet access required for managed instances

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- AWS Systems Manager permissions in your account

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - CIDR blocks for VPC and subnets

   - Instance types and availability zone

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
| `03_network.tf` | VPC, subnets, NAT Gateway, and VPC endpoints |
| `04_data_sources.tf` | AWS data sources |
| `05_iam_role.tf` | IAM role for Systems Manager |
| `06_instances_linux.tf` | EC2 instances in private subnet |
| `07_outputs.tf` | Output values |

## Usage

After deployment, wait a few minutes for instances to register with Systems Manager, then:

### Systems Manager Session Manager
```bash
# Connect to private instances via Session Manager (no SSH keys needed)
aws ssm start-session --target <PRIVATE-INSTANCE-ID>

# List managed instances
aws ssm describe-instance-information
```

### Systems Manager Run Command
```bash
# Execute commands on private instances
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=<INSTANCE-ID>" \
  --parameters 'commands=["uptime","df -h"]'
```

## Security Features

- Private instances have no direct internet access
- VPC endpoints provide secure Systems Manager communication

- IAM role with minimal required Systems Manager permissions
- Network ACLs and security groups with restricted access
- Encrypted EBS volumes

## VPC Endpoints

The following VPC endpoints are created for Systems Manager:
- **ssm**: Core Systems Manager service
- **ec2messages**: Message routing for Run Command and Session Manager
- **ssmmessages**: Session Manager communication

## Systems Manager Features

- **Session Manager**: Secure shell access without bastion hosts
- **Run Command**: Execute commands on multiple instances
- **Patch Manager**: Automated patch management
- **Parameter Store**: Secure configuration management
- **Private Communication**: All traffic stays within AWS network

## Cloud-Init Scripts

- Installs basic tools (zsh, nmap)
- Systems Manager agent is pre-installed on Amazon Linux 2

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes


- Private instances communicate with Systems Manager via VPC endpoints
- No internet gateway access required for managed instances
- VPC endpoints ensure secure, private communication
- All Systems Manager activities are logged in CloudTrail
