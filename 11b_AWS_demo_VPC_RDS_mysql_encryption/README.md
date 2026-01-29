# AWS VPC with RDS MySQL Encryption Demo

This Terraform project demonstrates AWS RDS MySQL database deployment with enforced encryption in transit, showcasing secure database connections.

## Architecture Overview

- **VPC** with multiple public subnets across availability zones
- **RDS MySQL Database** with enforced SSL/TLS encryption
- **EC2 instance** configured as MySQL client with SSL certificates
- **Encrypted connections** demonstrating secure database communication

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Multiple public subnets for RDS high availability
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **RDS MySQL Instance**: With custom parameter group enforcing encryption
- **SSL/TLS Enforcement**: `require_secure_transport=1` parameter
- **Multi-AZ Support**: Optional for high availability
- **Encrypted storage**: Configurable storage type and auto-scaling
- **Private access**: Database accessible only within VPC

### Security
- **DB Parameter Group**: Forces secure transport connections
- **SSL Certificates**: Global RDS certificate bundle for verification
- **Connection Scripts**: Both encrypted and non-encrypted examples

### Compute
- **EC2 Client Instance**: Amazon Linux 2 with MySQL client tools
- **SSL Certificates**: Pre-downloaded RDS global certificate bundle
- **Elastic IP**: Persistent public IP for SSH access

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
   - AWS region and availability zones
   - VPC and subnet CIDR blocks
   - Authorized IP addresses for SSH access
   - MySQL database configuration
   - Instance type and SSH key paths

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
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_rds_mysql.tf` | RDS MySQL with encryption enforcement |
| `07_instance_linux_al2.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, test both encrypted and non-encrypted connections.

### SSH Access
```bash
# Connect to the MySQL client instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>
```

### Database Connection Testing
Once connected to the EC2 instance:

```bash
# Test non-encrypted connection (should fail)
./mysql.sh
# This will fail due to require_secure_transport=1

# Test encrypted connection (should succeed)
./mysql_enc.sh
# Enter password when prompted
```

### Manual SSL Connection
```bash
# Connect with SSL verification
mysql -u admin -p -h <rds_endpoint> --ssl-ca=global-bundle.pem --ssl-verify-server-cert

# Verify SSL connection status
mysql> SHOW STATUS LIKE 'Ssl_cipher';
mysql> SHOW VARIABLES LIKE 'require_secure_transport';
```

## Security Features

- **Enforced SSL/TLS**: Database parameter group requires secure transport
- **Certificate Verification**: Uses AWS RDS global certificate bundle
- **Private Database**: No public access, VPC-only connectivity
- **Security Groups**: Restricted to MySQL port (3306) within VPC
- **Auto-generated Password**: Strong random password generation

## Encryption Configuration

- **Parameter Group**: Custom group with `require_secure_transport=1`
- **SSL Certificate**: AWS RDS global certificate bundle
- **Connection Verification**: Server certificate validation enabled
- **Transport Security**: All connections must use SSL/TLS

## Cloud-Init Features

- **MySQL Client**: Installation of MySQL command-line tools
- **SSL Certificate**: Automatic download of RDS global certificate bundle
- **Connection Scripts**: Both secure and insecure examples for testing
- **Network Tools**: Additional utilities for diagnostics

## Testing Encryption

The demo includes packet capture files (`.pcap`) showing:
- Unencrypted MySQL traffic (when possible)
- Encrypted MySQL traffic with SSL/TLS
- Network analysis capabilities

## Additional Scripts

- **Latency Testing**: Python script for database performance measurement
- **Network Scanning**: Shell script for network diagnostics

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database enforces SSL/TLS connections through parameter group
- Non-encrypted connections will be rejected by the database
- SSL certificate verification ensures connection authenticity
- Perfect for demonstrating database security best practices
- Includes network packet captures for educational purposes
- Consider this approach for production databases requiring encryption