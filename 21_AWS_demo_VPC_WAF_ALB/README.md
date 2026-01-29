# AWS VPC with WAF and ALB Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, Application Load Balancer, and AWS WAF (Web Application Firewall) for enhanced web application security.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **Bastion host** in public subnet for secure SSH access
- **Web servers** in private subnets behind an Application Load Balancer
- **AWS WAF** with geographic access control rules
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

### Load Balancing & Security
- Application Load Balancer with health checks
- AWS WAF WebACL with geographic filtering
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
| `08_ec2_instances_websrv.tf` | Web server instances |
| `09_elb_alb.tf` | Application Load Balancer setup |
| `10_waf_webacl.tf` | AWS WAF WebACL configuration |
| `11_outputs.tf` | Output values and SSH configuration |

## Usage

After deployment, wait a few minutes for the cloud-init scripts to complete, then:

### SSH Access
```bash
# Connect to bastion host
ssh -F sshcfg d21-bastion

# Connect to web servers (through bastion)
ssh -F sshcfg d21-ws1
ssh -F sshcfg d21-ws2
ssh -F sshcfg d21-ws3
```

### Web Access
- Main site: `http://<ALB-DNS-NAME>`
- Access is restricted by WAF rules (France and Germany only by default)

### WAF Management
```bash
# View WAF WebACL
aws wafv2 get-web-acl --scope REGIONAL --id <WEB-ACL-ID>

# Update WAF rules
aws wafv2 update-web-acl --scope REGIONAL --id <WEB-ACL-ID> --default-action Block={}
```

## Security Features

- Web servers in private subnets (no direct internet access)
- Bastion host for secure SSH access
- Security groups with minimal required access
- Auto-generated SSH key pairs
- IP-based access restrictions
- **AWS WAF** with geographic filtering (France and Germany allowed by default)

## WAF Features

- **Geographic Filtering**: Block/allow traffic based on country of origin
- **Default Block Action**: Blocks all traffic except explicitly allowed
- **Rule-based Access**: Configurable rules for traffic filtering
- **CloudWatch Integration**: Optional metrics and logging
- **ALB Association**: Direct integration with Application Load Balancer

## Cloud-Init Scripts

- **Bastion**: Installs nmap, applies updates, sets hostname
- **Web Servers**: Installs Apache/PHP, configures logging for ALB, applies updates

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- WAF rules can be customized by modifying the WebACL configuration
- Default WAF rule allows traffic from France (FR) and Germany (DE) only
- All other traffic is blocked by default
- WAF provides protection against common web exploits and attacks