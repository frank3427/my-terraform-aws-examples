# AWS VPC with EC2 Instance - Remote State in S3 Demo

This Terraform project demonstrates AWS infrastructure deployment with Terraform state file stored remotely in an S3 bucket, featuring a VPC and EC2 instance.

## Architecture Overview

- **VPC** with public subnet for EC2 instance
- **EC2 instance** with Amazon Linux 2 and Elastic IP
- **Remote state storage** in S3 bucket for team collaboration
- **Secure infrastructure** with encrypted storage and SSH access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet with internet gateway
- Default security group with SSH access restrictions

### Compute
- **EC2 Instance**: Amazon Linux 2 with configurable architecture (x86_64/ARM64)
- **Elastic IP**: Persistent public IP address
- **Encrypted Storage**: EBS root volume with default KMS encryption

### State Management
- **Remote Backend**: Terraform state stored in S3 bucket
- **Team Collaboration**: Shared state for multiple developers
- **State Security**: Centralized state management

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- **S3 bucket** pre-created for storing Terraform state

## Setup Instructions

1. **Create S3 bucket for state storage** (if not exists):
   ```bash
   aws s3 mb s3://your-terraform-state-bucket
   ```

2. **Clone and navigate to the project directory**

3. **Configure backend and variables**
   - Edit `02_provider.tf` to update S3 backend configuration:
     ```hcl
     terraform {
       backend "s3" {
         region = "your-region"
         bucket = "your-terraform-state-bucket"
         key    = "terraform/demo14.tfstate"
       }
     }
     ```
   
   - Copy and edit variables:
     ```bash
     cp terraform.tfvars.TEMPLATE terraform.tfvars
     ```

4. **Initialize Terraform**
   ```bash
   terraform init
   ```

5. **Plan the deployment**
   ```bash
   terraform plan
   ```

6. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

## Configuration Files

| File | Purpose |
|------|---------|
| `01_variables.tf` | Variable definitions |
| `02_provider.tf` | AWS provider and S3 backend configuration |
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_instance_linux.tf` | EC2 instance with outputs |
| `99_aws-whoami.tf` | AWS identity verification |

## Usage

After deployment, Terraform will output SSH connection instructions.

### SSH Access
```bash
# Connect to the instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>

# Or add to ~/.ssh/config and use alias
ssh d14
```

### State Management
```bash
# View current state
terraform show

# List resources in state
terraform state list

# View state file location
terraform state pull
```

## Security Features

- **Remote State**: State file stored securely in S3
- **Encrypted Storage**: EBS volumes encrypted with default KMS key
- **Security Groups**: SSH access restricted to authorized IPs
- **Auto-generated SSH Keys**: Secure key pair generation
- **Private IP Assignment**: Optional static private IP configuration

## Remote State Benefits

- **Team Collaboration**: Multiple developers can work with shared state
- **State Locking**: Prevents concurrent modifications (with DynamoDB)
- **State Backup**: S3 versioning provides state history
- **Security**: Centralized state management with access controls
- **Disaster Recovery**: State preserved even if local environment is lost

## Backend Configuration

The S3 backend is configured with:
- **Region**: Configurable AWS region
- **Bucket**: S3 bucket for state storage
- **Key**: Unique path for this project's state file
- **Encryption**: S3 server-side encryption (recommended)

## Cloud-Init Features

- **Package Installation**: Installs zsh, nmap, and other utilities
- **System Updates**: Applies latest security updates
- **Automatic Reboot**: Ensures clean startup after updates

## Important Notes

- **S3 Bucket**: Must be created before running `terraform init`
- **Backend Configuration**: Cannot use variables in backend configuration
- **State Locking**: Consider adding DynamoDB table for state locking
- **Bucket Versioning**: Enable S3 versioning for state history
- **Access Control**: Secure S3 bucket with appropriate IAM policies

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

Note: The state file will remain in S3 after destruction for audit purposes.

## Notes

- State file is stored remotely in S3 for team collaboration
- Backend configuration is hardcoded and cannot use variables
- Perfect for demonstrating Terraform remote state management
- Consider implementing state locking with DynamoDB for production use
- S3 bucket should have versioning enabled for state history
- Ensure proper IAM permissions for S3 bucket access