# AWS VPC with EC2 Instance - Remote State in S3 with DynamoDB Locking Demo

This Terraform project demonstrates AWS infrastructure deployment with Terraform state file stored remotely in S3 and state locking using DynamoDB, featuring a VPC and EC2 instance.

## Architecture Overview

- **VPC** with public subnet for EC2 instance
- **EC2 instance** with Amazon Linux 2 and Elastic IP
- **Remote state storage** in S3 bucket for team collaboration
- **State locking** with DynamoDB to prevent concurrent modifications
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
- **State Locking**: DynamoDB table prevents concurrent state modifications
- **Team Collaboration**: Safe shared state for multiple developers
- **Conflict Prevention**: Automatic locking during Terraform operations

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- **S3 bucket** pre-created for storing Terraform state
- **DynamoDB table** for state locking (created via provided script)

## Setup Instructions

1. **Create S3 bucket for state storage** (if not exists):
   ```bash
   aws s3 mb s3://your-terraform-state-bucket
   ```

2. **Create DynamoDB table for state locking**:
   ```bash
   ./00_create_dynamodb_table.sh
   ```

3. **Clone and navigate to the project directory**

4. **Configure backend and variables**
   - Edit `02_provider.tf` to update S3 backend configuration:
     ```hcl
     terraform {
       backend "s3" {
         region         = "your-region"
         bucket         = "your-terraform-state-bucket"
         key            = "terraform/demo14b.tfstate"
         dynamodb_table = "TerraformLock"
       }
     }
     ```
   
   - Copy and edit variables:
     ```bash
     cp terraform.tfvars.TEMPLATE terraform.tfvars
     ```

5. **Initialize Terraform**
   ```bash
   terraform init
   ```

6. **Plan the deployment**
   ```bash
   terraform plan
   ```

7. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

## Configuration Files

| File | Purpose |
|------|---------|
| `00_create_dynamodb_table.sh` | Script to create DynamoDB locking table |
| `01_variables.tf` | Variable definitions |
| `02_provider.tf` | AWS provider and S3 backend with DynamoDB locking |
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_instance_linux.tf` | EC2 instance with outputs |
| `99_aws-whoami.tf` | AWS identity verification |
| `99_delete_dynamodb_table.sh` | Script to cleanup DynamoDB table |

## Usage

After deployment, Terraform will output SSH connection instructions.

### SSH Access
```bash
# Connect to the instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>

# Or add to ~/.ssh/config and use alias
ssh d14b
```

### State Management with Locking
```bash
# View current state (automatically locks during operation)
terraform show

# List resources in state
terraform state list

# Plan with automatic locking
terraform plan

# Apply with automatic locking
terraform apply
```

## Security Features

- **Remote State**: State file stored securely in S3
- **State Locking**: DynamoDB prevents concurrent modifications
- **Encrypted Storage**: EBS volumes encrypted with default KMS key
- **Security Groups**: SSH access restricted to authorized IPs
- **Auto-generated SSH Keys**: Secure key pair generation
- **Private IP Assignment**: Optional static private IP configuration

## State Locking Benefits

- **Concurrent Protection**: Prevents multiple users from modifying state simultaneously
- **Data Integrity**: Ensures state consistency during operations
- **Team Safety**: Eliminates race conditions in team environments
- **Automatic Locking**: Transparent locking during plan/apply operations
- **Lock Information**: Shows who has the lock and when it was acquired

## DynamoDB Table Configuration

The locking table is configured with:
- **Table Name**: TerraformLock
- **Primary Key**: LockID (String)
- **Provisioned Throughput**: 5 read/write capacity units
- **Purpose**: Store lock information during Terraform operations

## Backend Configuration

The S3 backend with DynamoDB locking includes:
- **Region**: Configurable AWS region
- **Bucket**: S3 bucket for state storage
- **Key**: Unique path for this project's state file
- **DynamoDB Table**: Table name for state locking
- **Encryption**: S3 server-side encryption (recommended)

## Cloud-Init Features

- **Package Installation**: Installs zsh, nmap, and other utilities
- **System Updates**: Applies latest security updates
- **Automatic Reboot**: Ensures clean startup after updates

## Management Scripts

### Create DynamoDB Table
```bash
./00_create_dynamodb_table.sh
```

### Delete DynamoDB Table
```bash
./99_delete_dynamodb_table.sh
```

## Important Notes

- **DynamoDB Table**: Must be created before running `terraform init`
- **Backend Configuration**: Cannot use variables in backend configuration
- **Lock Timeout**: Terraform will wait for locks to be released
- **Manual Lock Removal**: Use AWS CLI if locks become stuck
- **Cost Consideration**: DynamoDB table incurs minimal ongoing costs

## Cleanup

1. **Destroy the infrastructure**:
   ```bash
   terraform destroy
   ```

2. **Delete DynamoDB table** (optional):
   ```bash
   ./99_delete_dynamodb_table.sh
   ```

## Notes

- State file is stored remotely in S3 with DynamoDB locking for team safety
- DynamoDB table prevents concurrent Terraform operations
- Perfect for demonstrating production-ready Terraform state management
- Lock information is automatically managed by Terraform
- Consider using higher capacity units for large teams
- Monitor DynamoDB costs for high-frequency operations