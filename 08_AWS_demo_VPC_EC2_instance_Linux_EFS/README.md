# AWS VPC with EFS Demo

This Terraform project demonstrates AWS Elastic File System (EFS) integration with an EC2 instance in a VPC, providing shared network storage.

## Architecture Overview

- **VPC** with public subnet for EC2 instance
- **EFS File System** with encryption enabled
- **EC2 instance** with automatic EFS mounting
- **Network storage** accessible across multiple instances and availability zones

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet with internet gateway
- Security groups allowing EFS NFS traffic

### Storage
- **EFS File System**: Encrypted, scalable network file system
- **EFS Mount Target**: Provides network access to the file system
- **Automatic mounting**: EFS mounted at boot time via cloud-init

### Compute
- **EC2 Instance**: Amazon Linux 2023 with EFS utilities pre-installed
- **Elastic IP**: Persistent public IP address

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
   - VPC and subnet CIDR blocks
   - Authorized IP addresses for SSH access
   - EFS mount point path
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
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_efs.tf` | EFS file system and mount target |
| `07_instance_linux.tf` | EC2 instance with EFS integration |

## Usage

After deployment, Terraform will output SSH connection instructions.

### SSH Access
```bash
# Connect to the instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>

# Or add to ~/.ssh/config and use alias
ssh d08
```

### EFS File System
The EFS file system is automatically mounted at the configured mount point (default: `/mnt/efs`):

```bash
# Check mounted file systems
df -h

# Test EFS functionality
cd /mnt/efs
echo "Hello EFS" > test.txt
cat test.txt

# Check EFS mount details
mount | grep efs
```

## Security Features

- EFS file system encrypted at rest and in transit
- Security groups configured for NFS traffic
- Auto-generated SSH key pairs
- Encrypted EBS root volume

## Cloud-Init Features

- **EFS Utils Installation**: Installs amazon-efs-utils package
- **Automatic Mounting**: Configures /etc/fstab for persistent mounting
- **TLS Encryption**: Mounts EFS with encryption in transit
- **Package Updates**: Installs additional tools and applies updates

## EFS Configuration

- **Performance Mode**: General Purpose (default)
- **Throughput Mode**: Bursting (default)
- **Encryption**: Enabled for data at rest
- **Mount Options**: TLS encryption for data in transit

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- EFS provides shared storage accessible from multiple instances
- File system scales automatically based on usage
- TLS encryption ensures data security in transit
- Perfect for shared application data, content repositories, and backup storage
- EFS mount target is created in the same subnet as the EC2 instance