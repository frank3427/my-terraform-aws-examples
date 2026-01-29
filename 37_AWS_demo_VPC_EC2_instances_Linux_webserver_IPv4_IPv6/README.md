# AWS VPC with EC2 Instances Linux Web Server IPv4/IPv6 Demo

This Terraform project demonstrates AWS infrastructure setup with dual-stack (IPv4/IPv6) networking, VPC, and EC2 instances running web servers accessible via both IPv4 and IPv6.

## Architecture Overview

- **VPC** with dual-stack IPv4/IPv6 support
- **Public Subnets** across multiple availability zones with IPv6 auto-assignment
- **EC2 Instances** with both IPv4 and IPv6 addresses running Apache web servers
- **Elastic IPs** for persistent IPv4 public addresses
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with IPv4 CIDR and auto-assigned IPv6 CIDR block
- Public subnets with dual-stack addressing
- Internet gateway with IPv4 and IPv6 routing
- Network ACLs configured for both IP versions
- Security groups allowing SSH and HTTP on both protocols

### Compute
- **EC2 Instances**: Amazon Linux with Apache web servers
- **Dual-Stack Addressing**: Both IPv4 and IPv6 connectivity
- **Elastic IPs**: Persistent IPv4 public addresses
- **Encrypted EBS**: Root volumes with GP3 storage

### Web Services
- Apache HTTP servers with PHP support
- Accessible via both IPv4 and IPv6 protocols
- Custom web pages showing instance information

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- IPv6-capable network connection for testing IPv6 functionality

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zones
   - CIDR blocks for VPC and subnets
   - Authorized IPv4 and IPv6 addresses for SSH/HTTP access
   - Instance types and private IP addresses

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
| `03_network.tf` | VPC, subnets, and dual-stack networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key generation |
| `06_instances_linux.tf` | EC2 instances with dual-stack addressing |
| `cloud_init/cloud_init_al.sh` | Instance initialization script |

## Usage

After deployment, Terraform will output connection and testing instructions:

### SSH Access
```bash
# Instance 1
ssh -i <private-key-path> ec2-user@<ELASTIC-IP-1>

# Instance 2  
ssh -i <private-key-path> ec2-user@<ELASTIC-IP-2>
```

### Web Access via IPv4
```bash
# Instance 1
http://<ELASTIC-IP-1>

# Instance 2
http://<ELASTIC-IP-2>
```

### Web Access via IPv6
```bash
# Instance 1
http://[<IPv6-ADDRESS-1>]

# Instance 2
http://[<IPv6-ADDRESS-2>]
```

### IPv6 Testing from Instances
```bash
# Test web servers via IPv6
curl -6 'http://[<IPv6-ADDRESS>]:80/'

# Ping via IPv6
ping6 <IPv6-ADDRESS>
```

## Dual-Stack Features

- **IPv4/IPv6 Routing**: Internet gateway configured for both protocols
- **Subnet Configuration**: Auto-assignment of IPv6 addresses
- **Security Groups**: Rules for both IPv4 and IPv6 traffic
- **Network ACLs**: Dual-stack access control lists
- **DNS Resolution**: Support for both A and AAAA records

## IPv6 Configuration

- **VPC IPv6 CIDR**: Automatically assigned by AWS
- **Subnet IPv6 CIDRs**: /64 subnets carved from VPC CIDR
- **Instance Addressing**: Manual and automatic IPv6 assignment
- **Internet Connectivity**: Direct IPv6 routing via internet gateway

## Security Features

- Encrypted EBS root volumes
- Security groups with protocol-specific rules
- Network ACLs for both IPv4 and IPv6
- IP-based access restrictions for both protocols
- Auto-generated SSH key pairs

## Cloud-Init Scripts

- **Amazon Linux**: Installs Apache, PHP, and basic tools
- **Web Server Setup**: Configures custom index pages
- **System Updates**: Applies latest security patches

## Monitoring

Test dual-stack connectivity:
```bash
# From instances, test IPv6 connectivity
curl -6 http://ipv6.google.com
ping6 2001:4860:4860::8888
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- IPv6 addresses are globally routable and directly accessible
- Network ACLs include rules for both IPv4 and IPv6 traffic
- SSH keys are automatically generated in the `sshkeys_generated/` directory
- IPv6 connectivity requires IPv6-capable internet connection
- Elastic IPs provide persistent IPv4 addresses across restarts