# AWS VPC with RDS Oracle Demo

This Terraform project demonstrates AWS RDS Oracle database deployment with an EC2 instance configured as a database client in a VPC.

## Architecture Overview

- **VPC** with multiple public subnets across availability zones
- **RDS Oracle Database** with custom Oracle Enterprise Edition
- **EC2 instance** configured as Oracle client with Instant Client
- **Database connectivity** through private networking within VPC

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Multiple public subnets for RDS high availability
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **RDS Oracle Instance**: Custom Oracle Enterprise Edition
- **Bring Your Own License**: BYOL licensing model
- **Encrypted storage**: GP2 storage with configurable size
- **Private access**: Database accessible only within VPC

### Compute
- **EC2 Client Instance**: Amazon Linux 2 with Oracle Instant Client
- **Oracle Tools**: SQLPlus and database utilities pre-installed
- **Elastic IP**: Persistent public IP for SSH access

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- Oracle license for BYOL model

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
   - Oracle database configuration (instance class, version, SID)
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
| `01_variables.tf` | Variable definitions for Oracle and client |
| `02_provider.tf` | AWS provider configuration |
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_rds_oracle.tf` | RDS Oracle database configuration |
| `07_instance_linux_al2.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions and database password.

### SSH Access
```bash
# Connect to the Oracle client instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>
```

### Database Connection
Once connected to the EC2 instance:

```bash
# Connect to Oracle database using the provided script
./sqlplus.sh

# Enter the password displayed in Terraform output
# Password: <generated_password>

# Test database connectivity
SQL> SELECT * FROM dual;
SQL> SELECT user FROM dual;
SQL> EXIT;
```

### Manual Connection
```bash
# Set environment variables (already configured in .bash_profile)
export PATH=$PATH:/usr/lib/oracle/21/client64/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/oracle/21/client64/lib
export TNS_ADMIN=/home/ec2-user/oradb

# Connect manually
sqlplus admin@<database_alias>
```

## Security Features

- Database in private subnets with no public access
- Security groups restricting access to Oracle port (1521)
- Auto-generated strong database password
- Encrypted EBS volumes
- VPC-only database connectivity

## Oracle Configuration

- **Engine**: Custom Oracle Enterprise Edition
- **Version**: 19.0.0.0.ru-2021-01.rur-2021-01.r1
- **License Model**: Bring Your Own License (BYOL)
- **Instance Class**: db.m5.large (configurable)
- **Storage**: GP2 with configurable allocation
- **Multi-AZ**: Disabled (can be enabled for production)

## Cloud-Init Features

- **Oracle Instant Client 21c**: Automatic installation and configuration
- **TNS Configuration**: Automatic tnsnames.ora setup
- **SQLPlus Script**: Ready-to-use database connection script
- **Environment Setup**: Oracle paths and variables configured

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is randomly generated and displayed in Terraform output
- Oracle Instant Client 21c is automatically installed on the EC2 instance
- Database is accessible only from within the VPC for security
- BYOL licensing requires valid Oracle licenses
- Perfect for Oracle database development and testing environments
- Consider enabling Multi-AZ for production deployments