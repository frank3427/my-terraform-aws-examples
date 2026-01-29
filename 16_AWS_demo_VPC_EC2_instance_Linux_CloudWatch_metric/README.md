# AWS VPC with EC2 Instance and CloudWatch Custom Metrics Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, EC2 instance, and custom CloudWatch metrics for memory monitoring.

## Architecture Overview

- **VPC** with public subnet
- **EC2 instance** with IAM role for CloudWatch access
- **Custom CloudWatch metrics** for memory usage monitoring
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for EC2 instance

### Compute
- **EC2 Instance**: Amazon Linux 2 with CloudWatch monitoring capabilities
- **Stress testing tools**: Pre-installed stress-ng for load generation

### Monitoring
- IAM role with CloudWatchAgentServerPolicy
- Custom memory usage metrics sent to CloudWatch
- Automated cron job for metric collection

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
   - CIDR blocks for VPC and subnet
   - Authorized IP addresses for SSH access
   - Instance type and availability zone

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
| `06_iam_role_for_cloudwatch.tf` | IAM role for CloudWatch access |
| `07_instance_linux.tf` | EC2 instance configuration |

## Usage

After deployment, wait a few minutes for the cloud-init scripts to complete, then:

### SSH Access
```bash
ssh -i sshkeys_generated/ssh_key_demo16.priv ec2-user@<INSTANCE-PUBLIC-IP>
```

### Generate Load for Testing
```bash
# Run stress test to generate CPU and memory load
./stress.sh
```

### Monitor CloudWatch Metrics
- Navigate to AWS CloudWatch console
- Check "EC2-Mem" namespace for custom memory metrics
- View memory usage trends for your instance

## Security Features

- EC2 instance with minimal required IAM permissions
- Security groups with SSH access restrictions
- Auto-generated SSH key pairs
- IP-based access restrictions

## Cloud-Init Scripts

- Installs monitoring tools (zsh, nmap, stress-ng)
- Creates memory monitoring script
- Sets up cron job for automated metric collection
- Configures stress testing capabilities

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- Memory metrics are collected every minute via cron job
- The instance includes stress-ng for load testing scenarios
- Custom metrics appear in CloudWatch under "EC2-Mem" namespace