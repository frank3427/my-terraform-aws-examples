# AWS VPC with RDS Aurora MySQL Serverless v2 Demo

This Terraform project demonstrates AWS RDS Aurora MySQL Serverless v2 deployment with instant scaling and an EC2 instance configured as a database client in a VPC.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **RDS Aurora MySQL Serverless v2** with instant scaling and no pause capability
- **EC2 instance** configured as MySQL client with database tools
- **Production-ready** serverless architecture with enhanced monitoring

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for database client instance
- Private subnets across 3 AZs for Aurora cluster
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **Aurora MySQL Serverless v2**: Next-generation serverless database
- **Instant Scaling**: Sub-second scaling without connection drops
- **No Auto-pause**: Always available, no cold starts
- **Performance Insights**: Enabled for query performance monitoring
- **Enhanced Monitoring**: 60-second interval monitoring
- **Private access**: Database accessible only within VPC

### Compute
- **EC2 Client Instance**: Amazon Linux 2 with MySQL client tools
- **MySQL Client**: Pre-installed for Aurora connectivity
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
   - Aurora MySQL configuration (cluster identifier, version)
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
| `06_rds_aurora_mysql_serverless_v2.tf` | Aurora Serverless v2 configuration |
| `07_instance_linux_db_client.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions, cluster endpoint, and password.

### SSH Access
```bash
# Connect to the MySQL client instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>
```

### Database Connection
Once connected to the EC2 instance:

```bash
# Set password environment variable
export MYSQL_PASSWD="<generated_password>"

# Connect to Aurora MySQL Serverless v2 cluster
./mysql.sh

# Test database connectivity (instant connection, no cold start)
mysql> SHOW DATABASES;
mysql> USE <database_name>;
mysql> SHOW TABLES;
```

### Sample Database Operations
```sql
-- Create a sample table
CREATE TABLE tblEmployee (
    Employee_id INT AUTO_INCREMENT PRIMARY KEY,
    Employee_first_name VARCHAR(500) NOT NULL,
    Employee_last_name VARCHAR(500) NOT NULL,
    Employee_Address VARCHAR(1000),
    Employee_emailID VARCHAR(500),
    Employee_department_ID INT DEFAULT 9,
    Employee_Joining_date DATE
);

-- Insert sample data
INSERT INTO tblEmployee (employee_first_name, employee_last_name, employee_joining_date) 
VALUES ('John', 'Doe', '2024-01-15');

-- Query data
SELECT * FROM tblEmployee;
```

## Security Features

- Aurora cluster in private subnets with no public access
- Security groups restricting access to MySQL port (3306)
- Auto-generated strong database password
- Encrypted EBS volumes
- VPC-only database connectivity

## Aurora Serverless v2 Configuration

- **Engine**: Aurora MySQL Serverless v2
- **Instance Class**: db.serverless
- **Scaling**: Configurable min/max Aurora Capacity Units (ACUs)
- **Instant Scaling**: Sub-second scaling without connection drops
- **No Auto-pause**: Always available for production workloads
- **Performance Insights**: Enabled for query analysis
- **Enhanced Monitoring**: 60-second interval monitoring
- **Backups**: 5-day retention with preferred backup window

## Serverless v2 Advantages

- **Instant Scaling**: Scales in sub-seconds without dropping connections
- **No Cold Starts**: Always warm and ready to serve requests
- **MySQL 8.0 Support**: Latest MySQL version compatibility
- **Production Ready**: Suitable for production workloads
- **Cost Efficient**: Pay only for actual capacity used
- **Better Performance**: Improved performance over Serverless v1

## Cloud-Init Features

- **MySQL Client**: Automatic installation for Aurora connectivity
- **Connection Script**: Ready-to-use database connection script
- **Network Tools**: Additional utilities for diagnostics

## Monitoring and Observability

- **Performance Insights**: Query performance monitoring and analysis
- **Enhanced Monitoring**: Detailed OS-level metrics every 60 seconds
- **CloudWatch Integration**: Standard CloudWatch metrics and alarms
- **Scaling Metrics**: Monitor ACU usage and scaling events

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is randomly generated and displayed in Terraform output
- Aurora Serverless v2 scales instantly based on demand without connection drops
- No auto-pause feature ensures consistent availability
- Perfect for production workloads with variable demand
- Supports MySQL 8.0 and latest Aurora features
- More expensive than Serverless v1 but provides better performance and availability