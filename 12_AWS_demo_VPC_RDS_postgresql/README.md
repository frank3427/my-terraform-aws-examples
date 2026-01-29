# AWS VPC with RDS PostgreSQL Demo

This Terraform project demonstrates AWS RDS PostgreSQL database deployment with an EC2 instance configured as a database client in a VPC.

## Architecture Overview

- **VPC** with multiple public subnets across availability zones
- **RDS PostgreSQL Database** with Multi-AZ deployment
- **EC2 instance** configured as PostgreSQL client with psql tools
- **Database connectivity** through private networking within VPC

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Multiple public subnets for RDS high availability
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **RDS PostgreSQL Instance**: Configurable version and instance class
- **Multi-AZ Deployment**: Enabled for high availability
- **Performance Insights**: Enabled with 7-day retention
- **Automated backups**: 7-day retention with daily backup window
- **Encrypted storage**: Configurable storage type and auto-scaling
- **Private access**: Database accessible only within VPC

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
   - PostgreSQL database configuration (instance class, version, storage)
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
| `01_variables.tf` | Variable definitions for PostgreSQL and client |
| `02_provider.tf` | AWS provider configuration |
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_rds_postgresql.tf` | RDS PostgreSQL database configuration |
| `07_instance_linux_al2.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions, database endpoint, and password.

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

### Manual SQL Operations
```sql
-- Create a sample table
CREATE TABLE tblEmployee (
    Employee_id INT PRIMARY KEY,
    Employee_first_name VARCHAR(500) NOT NULL,
    Employee_last_name VARCHAR(500) NOT NULL,
    Employee_Address VARCHAR(1000),
    Employee_emailID VARCHAR(500),
    Employee_department_ID INT DEFAULT 9,
    Employee_Joining_date DATE
);

-- Insert sample data
INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date) 
VALUES (1, 'John', 'Doe', '2024-01-15');

-- Query data
SELECT * FROM tblEmployee;
```

## Security Features

- Database in private subnets with no public access
- Security groups restricting access to PostgreSQL port (5432)
- Auto-generated strong database password
- Encrypted EBS volumes
- VPC-only database connectivity

## PostgreSQL Configuration

- **Engine**: PostgreSQL (configurable version)
- **Instance Class**: Configurable (e.g., db.t3.micro)
- **Storage**: GP2/GP3 with auto-scaling support
- **Multi-AZ**: Enabled for automatic failover
- **Performance Insights**: Enabled for query performance monitoring
- **Backups**: 7-day retention with daily backup window
- **Monitoring**: CloudWatch integration

## Cloud-Init Features

- **PostgreSQL Client**: Automatic installation of psql tools
- **Connection Script**: Ready-to-use database connection script with .pgpass
- **SQL Scripts**: Pre-configured sample SQL files
- **Network Tools**: Additional utilities for diagnostics

## Additional Features

- **CLI Scripts**: Shell scripts for database management operations
- **Read Replica Support**: Script for creating read replicas
- **Instance Modification**: Script for changing instance classes
- **SQL Script Library**: Complete CRUD operation examples

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is randomly generated and displayed in Terraform output
- PostgreSQL client uses .pgpass file for automatic authentication
- Database is accessible only from within the VPC for security
- Multi-AZ deployment provides automatic failover capability
- Performance Insights helps monitor query performance
- Perfect for PostgreSQL database development and testing environments
- Consider longer backup retention for production deployments