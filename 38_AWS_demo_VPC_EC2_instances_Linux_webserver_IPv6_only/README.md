# AWS VPC with EC2 Instances Linux Web Server IPv6-Only Demo

This Terraform project demonstrates AWS infrastructure setup with IPv6-only networking, VPC, and EC2 instances running web servers accessible exclusively via IPv6.

## Architecture Overview

- **VPC** with IPv6-only networking configuration
- **IPv6-Native Subnets** across multiple availability zones
- **EC2 Instances** with IPv6-only addresses running Apache web servers
- **No IPv4 Addresses** - pure IPv6 implementation
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with auto-assigned IPv6 CIDR block (no IPv4 CIDR)
- IPv6-native public subnets with automatic address assignment
- Internet gateway with IPv6-only routing
- Network ACLs configured exclusively for IPv6 traffic
- Security groups allowing SSH and HTTP on IPv6 only

### Compute
- **EC2 Instances**: Amazon Linux with Apache web servers
- **IPv6-Only Addressing**: No IPv4 connectivity
- **Native IPv6 Subnets**: Direct IPv6 internet connectivity
- **Encrypted EBS**: Root volumes with GP3 storage

### Web Services
- Apache HTTP servers with PHP support
- Accessible exclusively via IPv6 protocol
- Custom web pages showing instance information
- AAAA DNS records for hostname resolution

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client with IPv6 support
- **IPv6-capable network connection** (required for access)
- IPv6-enabled internet service provider

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zones
   - IPv4 CIDR for VPC (still required by AWS)
   - **Authorized IPv6 addresses** for SSH/HTTP access
   - Instance types

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
| `03_network.tf` | VPC and IPv6-native subnets |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key generation |
| `06_instances_linux.tf` | EC2 instances with IPv6-only addressing |
| `cloud_init/cloud_init_al.sh` | Instance initialization script |

## Usage

After deployment, Terraform will output IPv6-only connection instructions:

### SSH Access (IPv6 Only)
```bash
# Instance 1
ssh -i <private-key-path> ec2-user@<IPv6-ADDRESS-1>

# Instance 2  
ssh -i <private-key-path> ec2-user@<IPv6-ADDRESS-2>
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

# Test external IPv6 connectivity
curl -6 http://ipv6.google.com
ping6 2001:4860:4860::8888
```

## IPv6-Only Features

- **Native IPv6 Subnets**: No IPv4 addresses assigned
- **Direct Internet Access**: IPv6 traffic routes directly via IGW
- **AAAA DNS Records**: Automatic IPv6 hostname resolution
- **Pure IPv6 Stack**: No dual-stack configuration
- **Cost Optimization**: No IPv4 address charges

## IPv6 Configuration

- **VPC IPv6 CIDR**: Automatically assigned by AWS (/56)
- **Subnet IPv6 CIDRs**: /64 subnets from VPC CIDR
- **Instance Addressing**: Manual and automatic IPv6 assignment
- **Internet Connectivity**: Direct IPv6 routing (no NAT required)

## Security Features

- Encrypted EBS root volumes
- Security groups with IPv6-only rules
- Network ACLs configured for IPv6 traffic
- IPv6 address-based access restrictions
- Auto-generated SSH key pairs

## Network Requirements

**Important**: This setup requires IPv6 connectivity:
- Your ISP must support IPv6
- Your local network must be IPv6-enabled
- Your client devices must have IPv6 addresses
- Firewalls must allow IPv6 traffic

## Cloud-Init Scripts

- **Amazon Linux**: Installs Apache, PHP, and basic tools
- **Web Server Setup**: Configures custom index pages
- **IPv6 Optimization**: Ensures IPv6-only operation

## Monitoring

Test IPv6-only connectivity:
```bash
# From instances, verify IPv6-only operation
ip addr show  # Should show no IPv4 addresses
curl -6 http://ipv6.google.com
nslookup -type=AAAA google.com
```

## Troubleshooting

If you cannot connect:
1. Verify your IPv6 connectivity: `curl -6 http://ipv6.google.com`
2. Check your IPv6 address: `curl -6 http://ipv6.icanhazip.com`
3. Ensure authorized_ips_v6 includes your IPv6 prefix
4. Verify firewall allows IPv6 traffic

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- **IPv6 connectivity is mandatory** - no IPv4 fallback available
- Instances have no IPv4 addresses (public or private)
- SSH keys are automatically generated in the `sshkeys_generated/` directory
- Network ACLs and security groups are IPv6-only
- This demonstrates AWS's IPv6-native subnet capability
- Cost savings from no IPv4 address allocation