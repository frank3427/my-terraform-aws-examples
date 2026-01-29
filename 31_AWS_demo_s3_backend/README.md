# AWS S3 Backend Demo

This Terraform project demonstrates how to use AWS S3 as a remote backend for Terraform state files with DynamoDB for state locking, along with a basic VPC and EC2 instance setup.

## Architecture Overview

- **S3 Bucket** for remote Terraform state storage with versioning and encryption
- **DynamoDB Table** for Terraform state locking
- **VPC** with public subnet
- **EC2 Instance** in public subnet for demonstration

## Infrastructure Components

### Remote State Management
- S3 bucket with versioning enabled for state file storage
- Server-side encryption (AES256) for state file security
- DynamoDB table for state locking to prevent concurrent modifications

### Network
- VPC with configurable CIDR block
- Public subnet for EC2 instance

### Compute
- **EC2 Instance**: Linux instance in public subnet with SSH access

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances

## Setup Instructions

### Step 1: Create S3 Backend Prerequisites

1. **Navigate to the prerequisites directory**
   ```bash
   cd 00_PREREQ/
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values for S3 bucket and DynamoDB table.

3. **Deploy the backend infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Step 2: Deploy Main Infrastructure

1. **Return to main directory**
   ```bash
   cd ..
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - CIDR blocks for VPC and subnet
   - Authorized IP addresses for SSH access
   - Instance type and availability zone

3. **Initialize Terraform with S3 backend**
   ```bash
   terraform init
   ```

4. **Plan and deploy**
   ```bash
   terraform plan
   terraform apply
   ```

## Configuration Files

### Prerequisites (00_PREREQ/)
| File | Purpose |
|------|------------|
| `01_variables.tf` | Variable definitions for backend |
| `02_provider.tf` | AWS provider configuration |
| `03_s3_bucket.tf` | S3 bucket for state storage |
| `04_dynamodb_table.tf` | DynamoDB table for state locking |

### Main Infrastructure
| File | Purpose |
|------|------------|
| `01_variables.tf` | Variable definitions |
| `02_provider.tf` | AWS provider with S3 backend configuration |
| `03_network.tf` | VPC and subnet configuration |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key generation |
| `06_instance_linux.tf` | EC2 instance configuration |

## Usage

After deployment, you can connect to the EC2 instance using the generated SSH keys:

```bash
ssh -i sshkeys_generated/ssh_key_demo31 ec2-user@<INSTANCE-PUBLIC-IP>
```

## Security Features

- S3 bucket with server-side encryption
- Versioning enabled for state file recovery
- DynamoDB state locking prevents concurrent modifications
- Security groups with IP-based access restrictions
- Auto-generated SSH key pairs

## Remote State Benefits

- **Collaboration**: Multiple team members can work with the same state
- **Security**: State stored securely in S3 with encryption
- **Locking**: DynamoDB prevents concurrent state modifications
- **Versioning**: State file history for rollback capabilities
- **Backup**: Automatic state file backup and recovery

## Cleanup

To destroy the infrastructure:

1. **Destroy main infrastructure first**
   ```bash
   terraform destroy
   ```

2. **Destroy backend infrastructure**
   ```bash
   cd 00_PREREQ/
   terraform destroy
   ```

## Notes

- The S3 bucket and DynamoDB table must be created before using the S3 backend
- SSH keys are automatically generated in the `sshkeys_generated/` directory
- State locking ensures safe concurrent Terraform operations
- The S3 backend configuration is hardcoded in `02_provider.tf` and should be updated for your environment