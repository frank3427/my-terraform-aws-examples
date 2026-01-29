# AWS VPC with RDS Aurora PostgreSQL Serverless v2 Demo

This Terraform project demonstrates AWS RDS Aurora PostgreSQL Serverless v2 deployment with instant scaling and an EC2 instance configured as a database client in a VPC.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **RDS Aurora PostgreSQL Serverless v2** with instant scaling and writer/reader instances
- **EC2 instance** configured as PostgreSQL client with database tools
- **Production-ready** serverless PostgreSQL architecture with enhanced monitoring

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for database client instance
- Private subnets across 3 AZs for Aurora cluster
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **Aurora PostgreSQL Serverless v2**: Next-generation serverless PostgreSQL
- **Writer/Reader Instances**: 1 writer + 1 reader instance configuration
- **Instant Scaling**: Sub-second scaling without connection drops
- **No Auto-pause**: Always available, no cold starts
- **Performance Insights**: Enabled for query performance monitoring
- **Private access**: Database accessible only within VPC

### Compute
- **EC2 Client Instance**: Amazon Linux with PostgreSQL client tools
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
   - Aurora PostgreSQL configuration (cluster identifier, version)
   - Serverless v2 scaling configuration (min/max ACUs)
   - Database name and instance settings

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
| `01_variables.tf` | Variable definitions for Aurora and client |
| `02_provider.tf` | AWS provider configuration |
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_rds_aurora_postgresql_serverless_v2.tf` | Aurora PostgreSQL Serverless v2 configuration |
| `07_instance_linux_db_client.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions, cluster endpoint, and password.

### SSH Access
```bash
# Connect to the PostgreSQL client instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>
```

### Database Connection
Once connected to the EC2 instance:

```bash
# Connect to Aurora PostgreSQL Serverless v2 cluster
./psql.sh

# Test database connectivity (instant connection, no cold start)
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

- Aurora cluster in private subnets with no public access
- Security groups restricting access to PostgreSQL port (5432)
- Auto-generated strong database password
- Encrypted EBS volumes
- VPC-only database connectivity

## Aurora PostgreSQL Serverless v2 Configuration

- **Engine**: Aurora PostgreSQL Serverless v2
- **Instance Class**: db.serverless
- **Cluster Configuration**: 1 writer + 1 reader instance
- **Scaling**: Configurable min/max Aurora Capacity Units (ACUs)
- **Instant Scaling**: Sub-second scaling without connection drops
- **No Auto-pause**: Always available for production workloads
- **Performance Insights**: Enabled for query analysis
- **Backups**: 5-day retention with preferred backup window

## Serverless v2 Advantages

- **Instant Scaling**: Scales in sub-seconds without dropping connections
- **No Cold Starts**: Always warm and ready to serve requests
- **PostgreSQL Compatibility**: Latest PostgreSQL version support
- **Production Ready**: Suitable for production workloads
- **Cost Efficient**: Pay only for actual capacity used
- **High Availability**: Writer/reader configuration for load distribution

## Cloud-Init Features

- **PostgreSQL Client**: Automatic installation of psql tools
- **Connection Script**: Ready-to-use database connection script with .pgpass
- **SQL Scripts**: Pre-configured sample SQL files
- **Network Tools**: Additional utilities for diagnostics

## SQL Script Library

The project includes a complete set of SQL scripts for common operations:
- **01_create_table.sql**: Creates sample employee table
- **02_select_from_table.sql**: Queries data from table
- **03_insert_into_table.sql**: Inserts sample data
- **04_drop_table.sql**: Drops the table

## Monitoring and Observability

- **Performance Insights**: Query performance monitoring and analysis
- **CloudWatch Integration**: Standard CloudWatch metrics and alarms
- **Scaling Metrics**: Monitor ACU usage and scaling events
- **Connection Monitoring**: Track database connections and performance

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is randomly generated and displayed in Terraform output
- PostgreSQL client uses .pgpass file for automatic authentication
- Aurora PostgreSQL Serverless v2 scales instantly based on demand
- No auto-pause feature ensures consistent availability
- Perfect for PostgreSQL workloads with variable demand
- Supports latest PostgreSQL features and extensions
- Writer/reader configuration allows for read scaling