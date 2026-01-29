# AWS VPC with RDS Aurora MySQL Serverless v1 Demo

This Terraform project demonstrates AWS RDS Aurora MySQL Serverless v1 deployment with automatic scaling and an EC2 instance configured as a database client in a VPC.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **RDS Aurora MySQL Serverless v1** with automatic scaling and pause capability
- **EC2 instance** configured as MySQL client with database tools
- **Cost-optimized** serverless architecture that scales to zero when idle

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for database client instance
- Private subnets across 3 AZs for Aurora cluster
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **Aurora MySQL Serverless v1**: Auto-scaling database cluster
- **Auto-pause**: Automatically pauses after 5 minutes of inactivity
- **Scaling Configuration**: Min 2 ACUs, Max 256 ACUs
- **Automated backups**: 5-day retention with preferred backup window
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
   - Database name and scaling settings
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
| `06_rds_aurora_mysql_serverless_v1.tf` | Aurora Serverless v1 configuration |
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

# Connect to Aurora MySQL Serverless cluster
./mysql.sh

# Test database connectivity (may take time to wake up from pause)
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

## Aurora Serverless v1 Configuration

- **Engine**: Aurora MySQL Serverless v1
- **Engine Mode**: Serverless (v1)
- **Scaling**: 2-256 Aurora Capacity Units (ACUs)
- **Auto-pause**: Enabled after 5 minutes of inactivity
- **Timeout Action**: Force apply capacity changes
- **Backups**: 5-day retention with preferred backup window
- **Cost Optimization**: Pay only for actual usage

## Cloud-Init Features

- **MySQL Client**: Automatic installation for Aurora connectivity
- **Connection Script**: Ready-to-use database connection script
- **Network Tools**: Additional utilities for diagnostics

## Upgrade Path to Serverless v2

The project includes upgrade scripts in the `_upgrade_serverless_v1_to_v2/` directory:

1. **Create Parameter Group**: `1_create_attach_new_param_group.sh`
2. **Convert to Provisioned**: `2_convert_serverless_v1_to_provisioned.sh`
3. **Blue-Green Upgrade**: `3_blue_green_upgrade_mysql_from_5.7_to_8.0.sh`
4. **Convert to Serverless v2**: `4_convert_provisioned_to_serverless_v2.sh`
5. **Failover**: `5_failover_green_cluster_to_serverless_v2.sh`
6. **Cleanup**: `6_green_cluster_delete_provisioned_instance.sh`
7. **Final Failover**: `7_blue_green_failover.sh`
8. **Blue-Green Cleanup**: `8_blue_green_cleanup.sh`

## Important Notes

- **Cold Start**: First connection after pause may take 15-30 seconds
- **Serverless v1 Limitations**: Limited to MySQL 5.7, deprecated in favor of v2
- **Auto-pause**: Database pauses automatically to save costs
- **Scaling**: Automatic scaling based on workload demand

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is randomly generated and displayed in Terraform output
- Aurora Serverless v1 automatically scales based on demand
- Database pauses when idle to minimize costs
- Perfect for development, testing, and variable workloads
- Consider migrating to Aurora Serverless v2 for production workloads
- Serverless v1 is deprecated and not recommended for new deployments