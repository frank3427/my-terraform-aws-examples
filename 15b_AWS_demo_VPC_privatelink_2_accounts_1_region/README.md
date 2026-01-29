# AWS VPC PrivateLink Demo - Cross-Account Single Region

This Terraform project demonstrates AWS PrivateLink connectivity between two VPCs in different AWS accounts within the same region, enabling secure cross-account private communication.

## Architecture Overview

- **Account 1 (Provider)**: VPC with web services behind a Network Load Balancer
- **Account 2 (Consumer)**: VPC accessing services via PrivateLink endpoint
- **Cross-account PrivateLink**: Secure private connectivity between accounts
- **No internet routing** for cross-account service communication

## Infrastructure Components

### Account 1 - Provider VPC (Service Provider)
- **Public subnet**: Bastion host and Network Load Balancer
- **Private subnet**: Web servers serving HTTP content
- **Network Load Balancer**: Load balances traffic to web servers
- **VPC Endpoint Service**: Exposes NLB via PrivateLink with cross-account permissions
- **Bastion host**: SSH access to private web servers

### Account 2 - Consumer VPC (Service Consumer)
- **Public subnet**: Consumer instance and VPC endpoint
- **VPC Endpoint**: Interface endpoint to access provider services
- **Bastion host**: Test client for accessing provider services

### Cross-Account PrivateLink Components
- **Endpoint Service**: Provider-side service exposure with allowed principals
- **VPC Endpoint**: Consumer-side service access across accounts
- **IAM Permissions**: Cross-account access controls
- **Private connectivity**: Secure communication without account boundaries

## Prerequisites

- Terraform installed
- AWS CLI configured with credentials for both accounts
- SSH client for connecting to instances
- **Two AWS accounts** with appropriate permissions
- **AWS CLI profiles** configured for both accounts

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
   - AWS region (same for both accounts)
   - AWS CLI profile names for both accounts
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
| `01_variables.tf` | Variable definitions for both accounts |
| `02_provider.tf` | AWS provider configuration for both accounts |
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
# Connect to Account 1 provider bastion
ssh -i <account1_bastion_key> ec2-user@<account1_bastion_ip>

# Connect to Account 2 consumer bastion
ssh -i <account2_bastion_key> ec2-user@<account2_bastion_ip>
```

### Testing Cross-Account PrivateLink Connectivity
From the Account 2 consumer bastion instance:

```bash
# Test connectivity to Account 1 provider services via PrivateLink
curl http://<vpc_endpoint_dns_name>

# The request will be routed through PrivateLink across accounts
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

- **Cross-account isolation**: Services remain isolated between accounts
- **Private connectivity**: No internet routing for cross-account communication
- **IAM-based access control**: Allowed principals configuration
- **Network isolation**: Services remain in private subnets
- **Security groups**: Restrictive access controls per account

## Cross-Account PrivateLink Configuration

- **Endpoint Service**: Configured with allowed principals for Account 2
- **Acceptance Required**: Set to false for automatic acceptance
- **VPC Endpoint**: Interface endpoint in consumer account
- **IAM Role Detection**: Automatic detection of consumer account role
- **Cross-Account Permissions**: Proper IAM role-based access

## Multi-Account Provider Setup

The configuration uses AWS provider aliases:
- **aws.acct1**: Provider account resources
- **aws.acct2**: Consumer account resources
- **Profile-based authentication**: Uses AWS CLI profiles
- **Cross-account data sources**: Retrieves account information

## Cloud-Init Features

- **Account 1 Bastion**: Network tools and SSH configuration
- **Account 1 Web Servers**: Apache HTTP server with account-specific content
- **Account 2 Bastion**: HTTP client tools for cross-account testing

## Testing Scenarios

1. **Account 1 NLB Access**: Test from provider bastion to NLB
2. **Cross-Account PrivateLink**: Test from consumer bastion via VPC endpoint
3. **Private Subnet Access**: SSH to web servers via provider bastion
4. **Account Isolation**: Verify proper cross-account access controls

## Important Notes

- **AWS CLI Profiles**: Both accounts must be configured with AWS CLI profiles
- **IAM Permissions**: Ensure proper cross-account IAM permissions
- **Account IDs**: Terraform automatically detects and configures account IDs
- **Same Region**: Both accounts must be in the same AWS region
- **Billing**: PrivateLink charges apply to both accounts

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Demonstrates secure cross-account service access via PrivateLink
- No VPC peering or internet routing required between accounts
- Automatic IAM role detection for cross-account permissions
- Perfect for multi-account architectures requiring private connectivity
- Supports enterprise scenarios with account separation
- PrivateLink provides secure, scalable cross-account communication