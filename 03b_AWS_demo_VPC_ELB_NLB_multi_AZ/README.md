# AWS VPC with Network Load Balancer (Multi-AZ) Demo

This Terraform project demonstrates a complete AWS infrastructure setup with VPC, Network Load Balancer (NLB), and web servers in a highly available multi-AZ configuration.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **Bastion host** in public subnet for secure SSH access
- **Web servers** in private subnets behind a Network Load Balancer
- **Network Load Balancer** for high-performance load balancing across AZs
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnets for bastion host and load balancer (multi-AZ)
- Private subnets for web servers (multi-AZ)

### Compute
- **Bastion Host**: Secure jump server for SSH access to private instances
- **Web Servers**: Apache HTTP servers with PHP support distributed across AZs

### Load Balancing
- Network Load Balancer with health checks
- Layer 4 load balancing for high performance
- Cross-zone load balancing for high availability

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
| `08_ec2_instances_websrv.tf` | Web server instances |
| `09_elb_nlb.tf` | Network Load Balancer setup |
| `10_outputs.tf` | Output values and SSH configuration |

## Usage

After deployment, Terraform will output connection instructions. Wait a few minutes for the cloud-init scripts to complete, then:

### SSH Access
```bash
# Connect to bastion host
ssh -F sshcfg d03b-bastion

# Connect to web servers (through bastion)
ssh -F sshcfg d03b-ws1
ssh -F sshcfg d03b-ws2
ssh -F sshcfg d03b-ws3
```

### Web Access
- Access via NLB: `http://<NLB-DNS-NAME>`

### Monitoring
View web server access logs:
```bash
sudo tail -f /var/log/httpd/access_log
```

## Security Features

- Web servers in private subnets (no direct internet access)
- Bastion host for secure SSH access
- Security groups with minimal required access
- Auto-generated SSH key pairs
- IP-based access restrictions
- Multi-AZ deployment for high availability

## Cloud-Init Scripts

- **Bastion**: Installs nmap, applies updates, sets hostname
- **Web Servers**: Installs Apache/PHP, applies updates

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- The SSH configuration file (`sshcfg`) is automatically created for easy access
- Multi-AZ deployment provides high availability and fault tolerance
- All instances are automatically updated during provisioning