# AWS VPC with RDS PostgreSQL and Secrets Manager Demo

This Terraform project demonstrates AWS RDS PostgreSQL database deployment with AWS Secrets Manager for password management and an EC2 instance configured as a database client.

## Architecture Overview

- **VPC** with multiple public subnets across availability zones
- **RDS PostgreSQL Database** with AWS Secrets Manager integration
- **AWS Secrets Manager** for automatic password generation and management
- **EC2 instance** configured as PostgreSQL client with automatic password retrieval
- **Database connectivity** through private networking within VPC

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Multiple public subnets for RDS high availability
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **RDS PostgreSQL Instance**: Configurable version and instance class
- **Secrets Manager Integration**: Automatic password generation and rotation
- **Performance Insights**: Enabled with 7-day retention
- **Automated backups**: 7-day retention with daily backup window
- **Encrypted storage**: Configurable storage type and auto-scaling
- **Private access**: Database accessible only within VPC

### Security
- **AWS Secrets Manager**: Automatic master password management
- **KMS Encryption**: Default KMS key for secret encryption
- **Password Retrieval**: Terraform retrieves password from Secrets Manager
- **Secure Storage**: Password stored in .pgpass file on client

### Compute
- **EC2 Client Instance**: Amazon Linux 2 with PostgreSQL client tools
- **PostgreSQL Client**: Pre-installed psql command-line interface
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
   - PostgreSQL database configuration
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
| `06_rds_postgresql.tf` | RDS PostgreSQL with Secrets Manager |
| `07_instance_linux_al2.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions, database endpoint, and retrieved password.

### SSH Access
```bash
# Connect to the PostgreSQL client instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>
```

### Database Connection
Once connected to the EC2 instance:

```bash
# Connect to PostgreSQL database using the provided script
./psql.sh

# Test database connectivity
postgres=> \l                    # List databases
postgres=> \c <database_name>    # Connect to specific database
postgres=> \dt                   # List tables
```

### SQL Script Execution
The demo includes pre-written SQL scripts:

```bash
# Create table
./psql.sh 01_create_table.sql

# Insert sample data
./psql.sh 03_insert_into_table.sql

# Query data
./psql.sh 02_select_from_table.sql

# Drop table
./psql.sh 04_drop_table.sql
```

## Security Features

- **Secrets Manager**: Automatic password generation and secure storage
- **KMS Encryption**: Secrets encrypted with AWS managed keys
- **No Hardcoded Passwords**: Password retrieved dynamically from Secrets Manager
- **Private Database**: No public access, VPC-only connectivity
- **Security Groups**: Restricted to PostgreSQL port (5432) within VPC
- **Encrypted EBS**: Root volumes encrypted

## Secrets Manager Integration

- **Automatic Generation**: RDS creates and manages master password
- **Secure Storage**: Password stored encrypted in Secrets Manager
- **Dynamic Retrieval**: Terraform retrieves password for client configuration
- **Rotation Ready**: Supports automatic password rotation (not enabled in demo)

## PostgreSQL Configuration

- **Engine**: PostgreSQL (configurable version)
- **Instance Class**: Configurable
- **Storage**: GP2/GP3 with auto-scaling support
- **Performance Insights**: Enabled for query performance monitoring
- **Backups**: 7-day retention with daily backup window
- **Single-AZ**: Configured for cost optimization

## Cloud-Init Features

- **PostgreSQL Client**: Automatic installation via amazon-linux-extras
- **Connection Script**: Ready-to-use database connection script
- **Password File**: Automatic .pgpass file creation with retrieved password
- **SQL Scripts**: Pre-configured sample SQL files

## Additional Features

- **CLI Scripts**: Shell scripts for database management operations
- **SQL Script Library**: Complete CRUD operation examples
- **Password Security**: No passwords stored in plain text files

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is automatically generated by AWS Secrets Manager
- Terraform retrieves the password and configures the client automatically
- PostgreSQL client uses .pgpass file for seamless authentication
- Database is accessible only from within the VPC for security
- Perfect demonstration of AWS Secrets Manager integration with RDS
- Consider enabling password rotation for production environments
- Secrets Manager provides audit trail for password access