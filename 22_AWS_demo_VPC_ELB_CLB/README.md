# AWS VPC with Classic Load Balancer (CLB) Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, Classic Load Balancer (CLB), and web servers in a highly available configuration.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **Bastion host** in public subnet for secure SSH access
- **Web servers** in private subnets behind a Classic Load Balancer
- **Classic Load Balancer** with health checks and cross-zone load balancing
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for bastion host
- Public subnets for load balancer (multi-AZ)
- Private subnets for web servers (multi-AZ)

### Compute
- **Bastion Host**: Secure jump server for SSH access to private instances
- **Web Servers**: Apache HTTP servers with PHP support in private subnets

### Load Balancing
- Classic Load Balancer with health checks
- Cross-zone load balancing enabled
- Connection draining for graceful instance removal

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
| `09_elb_clb.tf` | Classic Load Balancer setup |
| `10_outputs.tf` | Output values and SSH configuration |

## Usage

After deployment, wait a few minutes for the cloud-init scripts to complete, then:

### SSH Access
```bash
# Connect to bastion host
ssh -F sshcfg d22-bastion

# Connect to web servers (through bastion)
ssh -F sshcfg d22-ws1
ssh -F sshcfg d22-ws2
ssh -F sshcfg d22-ws3
```

### Web Access
- Main site: `http://<CLB-DNS-NAME>`

### Load Balancer Management
```bash
# View load balancer status
aws elb describe-load-balancers --load-balancer-names demo22-clb

# Check instance health
aws elb describe-instance-health --load-balancer-name demo22-clb
```

## Security Features

- Web servers in private subnets (no direct internet access)
- Bastion host for secure SSH access
- Security groups with minimal required access
- Auto-generated SSH key pairs
- IP-based access restrictions

## Classic Load Balancer Features

- **Layer 4 Load Balancing**: TCP/HTTP traffic distribution
- **Health Checks**: Automatic unhealthy instance detection
- **Cross-Zone Load Balancing**: Even distribution across availability zones
- **Connection Draining**: Graceful handling of instance removal
- **Sticky Sessions**: Optional session affinity support
- **SSL Termination**: HTTPS support (configurable)

## Cloud-Init Scripts

- **Bastion**: Installs nmap, applies updates, sets hostname
- **Web Servers**: Installs Apache/PHP, configures logging, applies updates

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- Classic Load Balancer operates at Layer 4 (TCP) and basic Layer 7 (HTTP)
- Cross-zone load balancing ensures even traffic distribution
- Connection draining allows graceful instance maintenance
- CLB is the legacy load balancer type (consider ALB/NLB for new deployments)