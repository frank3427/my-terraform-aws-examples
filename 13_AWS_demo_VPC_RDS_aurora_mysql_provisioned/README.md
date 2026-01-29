# AWS VPC with RDS Aurora MySQL Provisioned Demo

This Terraform project demonstrates AWS RDS Aurora MySQL cluster deployment with provisioned instances and an EC2 instance configured as a database client in a VPC.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **RDS Aurora MySQL Cluster** with provisioned instances (1 writer + 2 readers)
- **EC2 instance** configured as MySQL client with database tools
- **High availability** deployment across 3 availability zones

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for database client instance
- Private subnets across 3 AZs for Aurora cluster
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **Aurora MySQL Cluster**: Provisioned with 3 instances
- **High Availability**: Writer and reader instances across AZs
- **Automated backups**: 5-day retention with preferred backup window
- **Maintenance window**: Scheduled maintenance configuration
- **Private access**: Database accessible only within VPC

### Compute
- **EC2 Client Instance**: Amazon Linux 2023 with MySQL client tools
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
   - Aurora MySQL configuration (cluster identifier, version, instance class)
   - Database name and storage settings
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
| `01_variables.tf` | Variable definitions for Aurora and client |
| `02_provider.tf` | AWS provider configuration |
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_rds_aurora_mysql.tf` | Aurora MySQL cluster configuration |
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

# Connect to Aurora MySQL cluster
./mysql.sh

# Test database connectivity
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

## Aurora MySQL Configuration

- **Engine**: Aurora MySQL (configurable version)
- **Cluster**: 1 writer + 2 reader instances
- **Instance Class**: Configurable (e.g., db.r6g.large)
- **Multi-AZ**: Deployed across 3 availability zones
- **Backups**: 5-day retention with preferred backup window
- **Maintenance**: Scheduled maintenance window
- **High Availability**: Automatic failover capability

## Cloud-Init Features

- **MySQL Client**: Automatic installation for Aurora connectivity
- **Connection Script**: Ready-to-use database connection script
- **Network Tools**: Additional utilities for diagnostics

## Additional Scripts

- **Version Discovery**: Scripts to list available Aurora engine versions
- **list_versions_v1.sh**: Lists Aurora engine versions
- **list_versions_v2_v3.sh**: Lists Aurora MySQL versions

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is randomly generated and displayed in Terraform output
- Aurora cluster provides high availability with automatic failover
- Reader instances can be used for read-only workloads
- Database is accessible only from within the VPC for security
- Perfect for production-like MySQL workloads requiring high availability
- Consider Aurora Serverless for variable workloads
- Monitor costs as Aurora provisioned instances run continuously