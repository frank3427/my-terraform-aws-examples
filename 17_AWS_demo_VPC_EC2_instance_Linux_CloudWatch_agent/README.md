# AWS VPC with EC2 Instance and CloudWatch Agent Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, EC2 instance, and CloudWatch agent for comprehensive system monitoring.

## Architecture Overview

- **VPC** with public subnet
- **EC2 instance** with IAM role for CloudWatch access
- **CloudWatch agent** for automated system metrics collection
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for EC2 instance

### Compute
- **EC2 Instance**: Amazon Linux 2 with CloudWatch agent installed
- **Stress testing tools**: Pre-installed stress-ng for load generation

### Monitoring
- IAM role with CloudWatchAgentServerPolicy
- CloudWatch agent for system metrics (CPU, memory, disk, network)
- Automated metric collection and publishing

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
   - Instance type, architecture (x86_64/arm64), and availability zone

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
| `cloud_init/cloud_init_al2.sh` | Instance initialization script |

## Usage

After deployment, wait a few minutes for the cloud-init scripts to complete, then:

### SSH Access
```bash
ssh -i sshkeys_generated/ssh_key_demo17 ec2-user@<INSTANCE-PUBLIC-IP>
```

### Generate Load for Testing
```bash
# Run stress test to generate CPU and memory load
./stress.sh
```

### Monitor CloudWatch Metrics
- Navigate to AWS CloudWatch console
- Check "CWAgent" namespace for detailed system metrics
- View CPU, memory, disk, and network usage trends
- Access pre-configured dashboards for comprehensive monitoring

### CloudWatch Agent Management
```bash
# Check agent status
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -a query

# Restart agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -a restart
```

## Security Features

- EC2 instance with minimal required IAM permissions
- Security groups with SSH access restrictions
- Auto-generated SSH key pairs
- IP-based access restrictions

## Cloud-Init Scripts

- Installs monitoring tools (zsh, nmap, stress-ng)
- Installs and configures CloudWatch agent with custom configuration
- Sets up stress testing capabilities with memory and CPU load generation
- Configures CloudWatch agent to collect memory, swap, and process metrics
- Starts CloudWatch agent service automatically

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- CloudWatch agent uses custom configuration for enhanced monitoring
- The instance includes stress-ng for load testing scenarios
- Metrics appear in CloudWatch under "CWAgent" namespace
- Agent collects memory usage, swap usage, and process metrics
- AWS caller identity is logged to `aws-whoami.log` during deployment
- Supports both x86_64 and arm64 architectures