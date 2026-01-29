# AWS VPC with S3 and Linux EC2 Instance Demo

This Terraform project demonstrates a complete AWS infrastructure setup with VPC, S3 bucket, and Linux EC2 instance with IAM role for S3 access.

## Architecture Overview

- **VPC** with public subnet
- **Linux EC2 instance** with S3 access via IAM role
- **S3 bucket** for object storage
- **IAM role and instance profile** for secure S3 access
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for EC2 instance
- Internet Gateway for public access

### Compute
- **Linux EC2 Instance**: Amazon Linux with S3 access capabilities

### Storage
- **S3 Bucket**: Object storage with proper IAM permissions

### Security
- **IAM Role**: Grants EC2 instance access to S3 bucket
- **Instance Profile**: Attaches IAM role to EC2 instance

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
   - AWS region
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for SSH access
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
| `03_network.tf` | VPC, subnets, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_S3_bucket.tf` | S3 bucket configuration |
| `06_iam_role.tf` | IAM role and instance profile |
| `07_instance.tf` | Linux EC2 instance configuration |

## Usage

After deployment, connect to the Linux instance and test S3 access:

### SSH Access
```bash
# Connect to the instance
ssh -i sshkeys/ssh_key_demo05 ec2-user@<INSTANCE-PUBLIC-IP>
```

### S3 Operations
```bash
# List S3 buckets (should show your created bucket)
aws s3 ls

# Upload a file to S3
echo "Hello World" > test.txt
aws s3 cp test.txt s3://<BUCKET-NAME>/

# List objects in bucket
aws s3 ls s3://<BUCKET-NAME>/

# Download file from S3
aws s3 cp s3://<BUCKET-NAME>/test.txt downloaded.txt
```

## Security Features

- IAM role with least privilege access to S3
- Instance profile for secure credential management
- Security groups with SSH access restrictions
- Auto-generated SSH key pairs
- IP-based access control

## Cloud-Init Scripts

- **EC2 Instance**: Installs AWS CLI, applies updates, configures hostname

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are stored in the `sshkeys/` directory
- The EC2 instance has AWS CLI pre-installed and configured
- IAM role provides secure access without hardcoded credentials
- S3 bucket name must be globally unique