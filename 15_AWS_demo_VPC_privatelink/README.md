# AWS VPC PrivateLink Demo

This Terraform project demonstrates AWS PrivateLink connectivity between two VPCs in the same account and region, enabling private communication without internet routing.

## Architecture Overview

- **Provider VPC** with web services behind a Network Load Balancer
- **Consumer VPC** accessing services via PrivateLink endpoint
- **PrivateLink connection** enabling private cross-VPC communication
- **No internet routing** for service-to-service communication

## Infrastructure Components

### Provider VPC (Service Provider)
- **Public subnet**: Bastion host and Network Load Balancer
- **Private subnet**: Web servers serving HTTP content
- **Network Load Balancer**: Load balances traffic to web servers
- **VPC Endpoint Service**: Exposes NLB via PrivateLink
- **Bastion host**: SSH access to private web servers

### Consumer VPC (Service Consumer)
- **Public subnet**: Consumer instance and VPC endpoint
- **VPC Endpoint**: Interface endpoint to access provider services
- **Bastion host**: Test client for accessing provider services

### PrivateLink Components
- **Endpoint Service**: Provider-side service exposure
- **VPC Endpoint**: Consumer-side service access
- **Private connectivity**: No internet gateway traversal required

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
   - AWS region and availability zone
   - CIDR blocks for both VPCs and subnets
   - Authorized IP addresses for SSH access
   - Instance types and SSH key paths
   - Cloud-init scripts for different instance types

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
| `01_variables.tf` | Variable definitions for both VPCs |
| `02_provider.tf` | AWS provider configuration |
| `03_data_sources.tf` | AWS data sources |
| `04_pvd_network.tf` | Provider VPC networking |
| `05_pvd_ssh_key_pair_bastion.tf` | Provider bastion SSH keys |
| `06_pvd_ssh_key_pair_websrv.tf` | Provider web server SSH keys |
| `07_pvd_ec2_instance_bastion.tf` | Provider bastion instance |
| `08_pvd_ec2_instances_websrv.tf` | Provider web server instances |
| `09_pvd_elb_nlb.tf` | Network Load Balancer |
| `10_pvd_PRIVATELINK_endpoint_service.tf` | PrivateLink endpoint service |
| `11_csm_network.tf` | Consumer VPC networking |
| `12_csm_ssh_key_pair_bastion.tf` | Consumer bastion SSH keys |
| `13_csm_ec2_instance_bastion.tf` | Consumer bastion instance |
| `14_csm_PRIVATELINK_endpoint.tf` | PrivateLink VPC endpoint |
| `15_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions and testing commands.

### SSH Access
```bash
# Connect to provider bastion
ssh -i <provider_bastion_key> ec2-user@<provider_bastion_ip>

# Connect to consumer bastion
ssh -i <consumer_bastion_key> ec2-user@<consumer_bastion_ip>
```

### Testing PrivateLink Connectivity
From the consumer bastion instance:

```bash
# Test connectivity to provider services via PrivateLink
curl http://<vpc_endpoint_dns_name>

# The request will be routed through PrivateLink to the provider's web servers
# without traversing the internet
```

From the provider bastion instance:

```bash
# Connect to web servers in private subnet
ssh -i <websrv_key> ec2-user@<websrv_private_ip>

# Test local connectivity to web servers
curl http://<websrv_private_ip>
```

## Security Features

- **Private connectivity**: No internet routing for service communication
- **Network isolation**: Services remain in private subnets
- **Security groups**: Restrictive access controls
- **PrivateLink security**: AWS-managed secure connectivity
- **Bastion access**: Secure SSH access to private resources

## PrivateLink Configuration

- **Endpoint Service**: Configured with Network Load Balancer
- **Acceptance Required**: Set to false for automatic acceptance
- **VPC Endpoint**: Interface endpoint in consumer VPC
- **Private DNS**: Disabled for manual endpoint resolution
- **Security Groups**: Control access to endpoint

## Network Load Balancer

- **Listener**: Port 80 for HTTP traffic
- **Targets**: Web server instances in private subnet
- **Health Checks**: Automatic target health monitoring
- **Cross-zone**: Load balancing across availability zones

## Cloud-Init Features

- **Provider Bastion**: Network tools and SSH configuration
- **Provider Web Servers**: Apache HTTP server with custom content
- **Consumer Bastion**: HTTP client tools for testing

## Testing Scenarios

1. **Direct NLB Access**: Test from provider bastion to NLB
2. **PrivateLink Access**: Test from consumer bastion via VPC endpoint
3. **Private Subnet Access**: SSH to web servers via provider bastion
4. **Connectivity Verification**: Confirm no internet routing required

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- PrivateLink enables private connectivity without VPC peering
- Network Load Balancer is required for PrivateLink endpoint services
- VPC endpoints appear as ENIs in the consumer VPC
- No data transfer charges between VPCs in same region via PrivateLink
- Perfect for secure service-to-service communication
- Supports cross-account scenarios with proper permissions