# AWS VPC with Virtual IP (VIP) EC2 Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, EC2 instances, and Virtual IP (VIP) using Elastic Network Interface (ENI) for high availability scenarios.

## Architecture Overview

- **VPC** with public subnet
- **Bastion host** for secure SSH access
- **Web servers** with Virtual IP capability
- **Elastic Network Interface (ENI)** for VIP implementation
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for all instances

### Compute
- **Bastion Host**: Secure jump server for SSH access
- **Web Servers**: Apache HTTP servers with VIP capability
- **Virtual IP**: Movable IP address using ENI attachment

### High Availability
- ENI-based VIP for failover scenarios
- Elastic IP attached to VIP interface
- Configurable VIP ownership between instances

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
   - Instance types and availability zone
   - VIP configuration (`websrv_private_ip_vip`, `websrv_vip_owner`)

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
| `05_ssh_key_pair_bastion.tf` | SSH key generation for bastion |
| `06_ssh_key_pair_websrv.tf` | SSH key generation for web servers |
| `07_ec2_instance_bastion.tf` | Bastion host configuration |
| `08_ec2_instances_websrv.tf` | Web server instances |
| `09_eni_for_vip.tf` | ENI and VIP configuration |
| `10_outputs.tf` | Output values and SSH configuration |

## Usage

After deployment, wait a few minutes for the cloud-init scripts to complete, then:

### SSH Access
```bash
# Connect to bastion host
ssh -F sshcfg d19-bastion

# Connect to web servers (through bastion)
ssh -F sshcfg d19-ws1
ssh -F sshcfg d19-ws2
```

### Web Access
- VIP access: `http://<VIP-ELASTIC-IP>`
- Direct instance access: `http://<INSTANCE-IP>`

### VIP Management
```bash
# Move VIP to different instance (AWS CLI)
aws ec2 detach-network-interface --attachment-id <attachment-id>
aws ec2 attach-network-interface --network-interface-id <eni-id> --instance-id <new-instance-id> --device-index 1

# Check VIP status
aws ec2 describe-network-interfaces --network-interface-ids <eni-id>
```

## Security Features

- Security groups with minimal required access
- Auto-generated SSH key pairs
- IP-based access restrictions for VIP
- Bastion host for secure SSH access

## VIP Features

- **Elastic Network Interface**: Dedicated ENI for VIP
- **Elastic IP**: Public IP attached to VIP ENI
- **Configurable Ownership**: Specify which instance owns VIP initially
- **Manual Failover**: VIP can be moved between instances
- **High Availability**: Enables active-passive configurations

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
- VIP is initially attached to the instance specified by `websrv_vip_owner`
- ENI attachment allows VIP to be moved between instances for failover
- VIP provides a consistent IP address for high availability scenarios