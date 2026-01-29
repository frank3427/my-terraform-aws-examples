# AWS VPC PrivateLink Demo - Cross-Account Cross-Region

This Terraform project demonstrates AWS PrivateLink connectivity between two VPCs in different AWS accounts and different regions, enabling secure cross-account cross-region private communication.

## Architecture Overview

- **Account 1 (Provider)**: VPC with web services in one region
- **Account 2 (Consumer)**: VPC accessing services in a different region
- **Cross-account cross-region PrivateLink**: Secure private connectivity across accounts and regions
- **Global private connectivity** without internet routing

## Infrastructure Components

### Account 1 - Provider VPC (Service Provider)
- **Multiple availability zones**: High availability deployment
- **Public subnets**: Bastion host and Network Load Balancer
- **Private subnets**: Web servers serving HTTP content
- **Network Load Balancer**: Load balances traffic across AZs
- **VPC Endpoint Service**: Exposes NLB via PrivateLink with cross-account permissions
- **Bastion host**: SSH access to private web servers

### Account 2 - Consumer VPC (Service Consumer)
- **Different region**: Consumer VPC in separate AWS region
- **Public subnet**: Consumer instance and VPC endpoint
- **VPC Endpoint**: Interface endpoint to access provider services
- **Bastion host**: Test client for accessing provider services

### Cross-Account Cross-Region PrivateLink Components
- **Endpoint Service**: Provider-side service exposure with allowed principals
- **VPC Endpoint**: Consumer-side service access across accounts and regions
- **IAM Permissions**: Cross-account access controls
- **Regional connectivity**: Secure communication across AWS regions

## Prerequisites

- Terraform installed
- AWS CLI configured with credentials for both accounts
- SSH client for connecting to instances
- **Two AWS accounts** with appropriate permissions
- **AWS CLI profiles** configured for both accounts
- **Different regions** for provider and consumer

## Setup Instructions

1. **Configure AWS CLI profiles for both accounts**:
   ```bash
   aws configure --profile account1
   aws configure --profile account2
   ```

2. **Clone and navigate to the project directory**

3. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS regions for both accounts (different regions)
   - AWS CLI profile names for both accounts
   - Availability zones for both regions
   - CIDR blocks for both VPCs and subnets
   - Authorized IP addresses for SSH access
   - Instance types and SSH key paths

4. **Initialize Terraform**
   ```bash
   terraform init
   ```

5. **Plan the deployment**
   ```bash
   terraform plan
   ```

6. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

## Configuration Files

| File | Purpose |
|------|---------|
| `01_variables.tf` | Variable definitions for both accounts and regions |
| `02_provider.tf` | AWS provider configuration for both accounts/regions |
| `03_data_sources.tf` | AWS data sources |
| `04_acct1_pvd_network.tf` | Account 1 provider VPC networking |
| `05_acct1_pvd_ssh_key_pair_bastion.tf` | Account 1 bastion SSH keys |
| `06_acct1_pvd_ssh_key_pair_websrv.tf` | Account 1 web server SSH keys |
| `07_acct1_pvd_ec2_instance_bastion.tf` | Account 1 bastion instance |
| `08_acct1_pvd_ec2_instances_websrv.tf` | Account 1 web server instances |
| `09_acct1_pvd_elb_nlb.tf` | Account 1 Network Load Balancer |
| `10_acct1_pvd_PRIVATELINK_endpoint_service.tf` | Cross-account endpoint service |
| `11_acct2_csm_network.tf` | Account 2 consumer VPC networking |
| `12_acct2_csm_ssh_key_pair_bastion.tf` | Account 2 bastion SSH keys |
| `13_acct2_csm_ec2_instance_bastion.tf` | Account 2 bastion instance |
| `14_acct2_csm_PRIVATELINK_endpoint.tf` | Account 2 VPC endpoint |
| `15_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions and testing commands.

### SSH Access
```bash
# Connect to Account 1 provider bastion (Region 1)
ssh -i <account1_bastion_key> ec2-user@<account1_bastion_ip>

# Connect to Account 2 consumer bastion (Region 2)
ssh -i <account2_bastion_key> ec2-user@<account2_bastion_ip>
```

### Testing Cross-Account Cross-Region PrivateLink
From the Account 2 consumer bastion instance:

```bash
# Test connectivity to Account 1 provider services via PrivateLink
curl http://<vpc_endpoint_dns_name>

# The request will be routed through PrivateLink across accounts and regions
# without traversing the internet
```

From the Account 1 provider bastion instance:

```bash
# Connect to web servers in private subnet
ssh -i <websrv_key> ec2-user@<websrv_private_ip>

# Test local connectivity to web servers
curl http://<websrv_private_ip>
```

## Security Features

- **Cross-account cross-region isolation**: Services isolated across accounts and regions
- **Private connectivity**: No internet routing for cross-region communication
- **IAM-based access control**: Allowed principals configuration
- **Network isolation**: Services remain in private subnets
- **Regional security**: Security groups per region and account

## Cross-Region PrivateLink Configuration

- **Endpoint Service**: Configured with allowed principals for Account 2
- **Cross-Region Support**: PrivateLink works across AWS regions
- **Acceptance Required**: Set to false for automatic acceptance
- **VPC Endpoint**: Interface endpoint in consumer region
- **Regional DNS**: Endpoint DNS names resolve in consumer region

## Multi-Account Multi-Region Provider Setup

The configuration uses AWS provider aliases:
- **aws.acct1**: Provider account resources in Region 1
- **aws.acct2**: Consumer account resources in Region 2
- **Profile-based authentication**: Uses AWS CLI profiles
- **Regional configuration**: Different regions per account

## Cloud-Init Features

- **Account 1 Bastion**: Network tools and SSH configuration
- **Account 1 Web Servers**: Apache HTTP server with region-specific content
- **Account 2 Bastion**: HTTP client tools for cross-region testing

## Testing Scenarios

1. **Account 1 NLB Access**: Test from provider bastion to NLB
2. **Cross-Region PrivateLink**: Test from consumer bastion via VPC endpoint
3. **Private Subnet Access**: SSH to web servers via provider bastion
4. **Regional Isolation**: Verify proper cross-region access controls
5. **Latency Testing**: Measure cross-region response times

## Important Notes

- **AWS CLI Profiles**: Both accounts must be configured with AWS CLI profiles
- **Different Regions**: Provider and consumer can be in different regions
- **Cross-Region Charges**: Data transfer charges apply for cross-region traffic
- **IAM Permissions**: Ensure proper cross-account IAM permissions
- **Regional Availability**: PrivateLink must be available in both regions

## Cost Considerations

- **PrivateLink Charges**: Hourly charges for VPC endpoints in both accounts
- **Cross-Region Data Transfer**: Additional charges for cross-region traffic
- **NAT Gateway**: If used, additional charges apply
- **Load Balancer**: Network Load Balancer charges in provider account

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Demonstrates secure cross-account cross-region service access via PrivateLink
- No VPC peering or internet routing required between accounts or regions
- Perfect for global multi-account architectures
- Supports enterprise scenarios with geographic account separation
- PrivateLink provides secure, scalable cross-region communication
- Consider latency implications for cross-region connectivity