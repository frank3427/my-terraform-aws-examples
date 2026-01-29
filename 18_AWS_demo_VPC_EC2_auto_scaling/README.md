# AWS VPC with EC2 Auto Scaling Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, Application Load Balancer, and EC2 Auto Scaling Group for scalable web applications.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **Bastion host** in public subnet for secure SSH access
- **Auto Scaling Group** with web servers in private subnets behind ALB
- **Application Load Balancer** for traffic distribution
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for bastion host and load balancer
- Private subnets for web servers (multi-AZ)

### Compute
- **Bastion Host**: Secure jump server for SSH access to private instances
- **Auto Scaling Group**: Automatically manages web server instances
- **Launch Template**: Defines instance configuration for scaling

### Load Balancing
- Application Load Balancer with health checks
- Target group for auto-scaled instances
- Cross-zone load balancing

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
| `05_ssh_key_pair_bastion.tf` | SSH key generation for bastion |
| `06_ssh_key_pair_websrv.tf` | SSH key generation for web servers |
| `07_ec2_instance_bastion.tf` | Bastion host configuration |
| `08_elb_alb.tf` | Application Load Balancer setup |
| `09_ec2_asg.tf` | Auto Scaling Group and Launch Template |
| `10_outputs.tf` | Output values and SSH configuration |

## Usage

After deployment, wait a few minutes for the cloud-init scripts to complete, then:

### SSH Access
```bash
# Connect to bastion host
ssh -F sshcfg d18-bastion

# Connect to auto-scaled instances (through bastion)
ssh -F sshcfg d18-ws1
ssh -F sshcfg d18-ws2
```

### Web Access
- Main site: `http://<ALB-DNS-NAME>`
- Each request shows which server handled it

### Auto Scaling Management
```bash
# View current instances
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names demo18-asg

# Scale up/down (modify desired capacity)
aws autoscaling set-desired-capacity --auto-scaling-group-name demo18-asg --desired-capacity 3
```

## Security Features

- Web servers in private subnets (no direct internet access)
- Bastion host for secure SSH access
- Security groups with minimal required access
- Auto-generated SSH key pairs
- IP-based access restrictions

## Auto Scaling Features

- **Launch Template**: Standardized instance configuration
- **Rolling Updates**: Instance refresh strategy for updates
- **Multi-AZ Deployment**: Instances distributed across availability zones
- **Target Group Integration**: Automatic registration with load balancer
- **Health Checks**: ALB health checks for instance replacement

## Cloud-Init Scripts

- **Bastion**: Basic tools and updates
- **Web Servers**: Apache/PHP installation, sample page creation

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- Auto Scaling Group maintains desired capacity automatically
- Instances are automatically registered with the load balancer
- Rolling updates ensure zero-downtime deployments