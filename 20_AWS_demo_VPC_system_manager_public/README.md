# AWS VPC with Systems Manager (Public) Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, EC2 instances, and AWS Systems Manager for remote management in public subnets.

## Architecture Overview

- **VPC** with public subnet
- **EC2 instances** with IAM role for Systems Manager access
- **AWS Systems Manager** for remote instance management
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for EC2 instances

### Compute
- **EC2 Instances**: Amazon Linux 2 with Systems Manager agent
- **IAM Role**: Permissions for Systems Manager communication

### Management
- AWS Systems Manager Session Manager for shell access
- Systems Manager Run Command for remote execution
- Systems Manager Patch Manager for updates
- No SSH required for remote access

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
   - CIDR blocks for VPC and subnet
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
| `03_network.tf` | VPC, subnet, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key generation |
| `06_iam_role.tf` | IAM role for Systems Manager |
| `07_instances_linux.tf` | EC2 instances configuration |

## Usage

After deployment, wait a few minutes for instances to register with Systems Manager, then:

### Systems Manager Session Manager
```bash
# Connect via Session Manager (no SSH keys needed)
aws ssm start-session --target <INSTANCE-ID>

# List managed instances
aws ssm describe-instance-information
```

### SSH Access (Alternative)
```bash
# Traditional SSH access
ssh -F sshcfg d20-inst1
ssh -F sshcfg d20-inst2
```

### Systems Manager Run Command
```bash
# Execute commands remotely
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=<INSTANCE-ID>" \
  --parameters 'commands=["uptime","df -h"]'
```

### Patch Management
```bash
# Check patch compliance
aws ssm describe-instance-patch-states --instance-ids <INSTANCE-ID>

# Install patches
aws ssm send-command \
  --document-name "AWS-RunPatchBaseline" \
  --targets "Key=instanceids,Values=<INSTANCE-ID>"
```

## Security Features

- IAM role with minimal required Systems Manager permissions
- Security groups with SSH access restrictions
- Auto-generated SSH key pairs
- Session Manager provides secure shell access without SSH keys
- All Systems Manager communication is encrypted

## Systems Manager Features

- **Session Manager**: Browser-based shell access without SSH
- **Run Command**: Execute commands on multiple instances
- **Patch Manager**: Automated patch management
- **Parameter Store**: Secure configuration management
- **Inventory**: Collect system information
- **Compliance**: Monitor configuration compliance

## Cloud-Init Scripts

- Installs basic tools (zsh, nmap)
- Systems Manager agent is pre-installed on Amazon Linux 2

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- Systems Manager agent is pre-installed on Amazon Linux 2
- Instances must have internet access for Systems Manager communication
- Session Manager provides secure access without exposing SSH ports
- All Systems Manager activities are logged in CloudTrail