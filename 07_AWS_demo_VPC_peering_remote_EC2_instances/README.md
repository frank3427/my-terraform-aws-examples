# AWS Cross-Region VPC Peering Demo

This Terraform project demonstrates VPC peering between two VPCs in different AWS regions with EC2 instances that can communicate with each other across regions.

## Architecture Overview

- **Two VPCs** in different AWS regions with separate CIDR blocks
- **Cross-region VPC Peering Connection** enabling communication between regions
- **EC2 instances** in each VPC with public IP addresses
- **Cross-region connectivity** allowing instances to ping each other using private IPs

## Infrastructure Components

### Network
- **VPC 1**: First VPC in Region 1 with configurable CIDR block and public subnet
- **VPC 2**: Second VPC in Region 2 with configurable CIDR block and public subnet
- **Cross-Region VPC Peering**: Enables communication between VPCs in different regions
- **Internet Gateways**: One for each VPC to provide internet access
- **Route Tables**: Updated to route traffic between peered VPCs across regions

### Compute
- **Instance 1**: EC2 instance in Region 1 VPC with Elastic IP
- **Instance 2**: EC2 instance in Region 2 VPC with Elastic IP

### Security
- Security groups allowing SSH access and cross-region VPC communication
- Network ACLs configured for authorized IP access and cross-region peering traffic

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- Permissions for multi-region resource creation

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS regions for both VPCs
   - CIDR blocks for both VPCs and subnets
   - Authorized IP addresses for SSH access
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
| `01_variables.tf` | Variable definitions for both regions |
| `02_provider.tf` | AWS provider configuration for multi-region |
| `03_network1.tf` | Region 1 VPC and networking components |
| `04_network2.tf` | Region 2 VPC and networking components |
| `05_data_sources.tf` | AWS data sources |
| `06_ssh_key_pair.tf` | SSH key pair configuration |
| `07_instance1.tf` | EC2 instance in Region 1 |
| `08_instance2.tf` | EC2 instance in Region 2 |
| `09_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection commands and testing instructions.

### SSH Access
```bash
# Connect to instance in Region 1
ssh -i <private_key_path> ec2-user@<instance1_public_ip>

# Connect to instance in Region 2
ssh -i <private_key_path> ec2-user@<instance2_public_ip>
```

### Testing Cross-Region VPC Peering
Once connected to an instance in one region, test connectivity to the other region:

```bash
# From instance in Region 1, ping instance in Region 2
ping <instance2_private_ip>

# From instance in Region 2, ping instance in Region 1
ping <instance1_private_ip>
```

## Security Features

- Instances in separate regions with controlled cross-region peering
- Security groups allowing only necessary traffic
- Network ACLs with IP-based access restrictions
- Auto-generated SSH key pairs
- Encrypted EBS volumes

## Cloud-Init Scripts

- **Amazon Linux 2**: Installs zsh, nmap, applies updates, and reboots
- **Ubuntu**: Alternative cloud-init script available

## Important Notes

- **Cross-region peering**: Requires manual acceptance in some cases
- **Data transfer costs**: Cross-region traffic incurs additional charges
- **Latency considerations**: Network latency will be higher than same-region peering

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Both instances have Elastic IP addresses for persistent public connectivity
- Cross-region VPC peering enables global network architectures
- Route tables are automatically updated to enable cross-region communication
- All instances are automatically updated during provisioning
- Perfect for disaster recovery and global application deployments