# AWS VPC with Network Load Balancer (Multi-AZ) Demo

This Terraform project demonstrates a complete AWS infrastructure setup with VPC, Network Load Balancer (NLB), and web servers in a highly available multi-AZ configuration.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **Web servers** in private subnets behind a Network Load Balancer
- **Network Load Balancer** for high-performance load balancing across AZs
- **Session Manager** for secure shell access to instances
- **VPC Endpoints** for private Session Manager connectivity

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnets for load balancer (multi-AZ)
- Private subnets for web servers (multi-AZ)

### Compute
- **Web Servers**: Apache HTTP servers with PHP support distributed across AZs
- **Auto Scaling Group**: Manages web server instances across multiple AZs

### Load Balancing
- Network Load Balancer with health checks
- Layer 4 load balancing for high performance
- Cross-zone load balancing for high availability

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Session Manager plugin for AWS CLI (for instance access)

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for HTTP access
   - Instance types (Graviton-based only) and availability zones

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
| `05_iam_role_ssm.tf` | IAM role for Session Manager |
| `06_vpc_endpoints_ssm.tf` | VPC endpoints for Session Manager |
| `07_elb_nlb.tf` | Network Load Balancer setup |
| `08_ec2_asg_websrv.tf` | Auto Scaling Group and web server configuration |
| `09_outputs.tf` | Output values and connection information |

## Usage

After deployment, Terraform will output connection instructions. Wait a few minutes for the cloud-init scripts to complete, then:

### Session Manager Access
```bash
# Get instance IDs
aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=demo03c-websrv-asg" --query "Reservations[].Instances[].InstanceId" --output table

# Connect to web server instance
aws ssm start-session --target <INSTANCE-ID>
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
- Session Manager for secure shell access (no SSH keys required)
- VPC endpoints for private Session Manager connectivity
- Security groups with minimal required access
- IP-based access restrictions for load balancer
- Multi-AZ deployment for high availability

## Cloud-Init Scripts

- **Web Servers**: Installs Apache/PHP, applies updates

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Session Manager provides secure access without SSH keys or bastion hosts
- VPC endpoints ensure private connectivity to AWS Systems Manager
- Multi-AZ deployment provides high availability and fault tolerance
- All instances are automatically updated during provisioning
- IAM roles provide necessary permissions for Session Manager