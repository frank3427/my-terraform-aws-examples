# AWS VPC with RDS MySQL Demo

This Terraform project demonstrates AWS RDS MySQL database deployment with an EC2 instance configured as a database client in a VPC.

## Architecture Overview

- **VPC** with multiple public subnets across availability zones
- **RDS MySQL Database** with configurable Multi-AZ deployment
- **EC2 instance** configured as MySQL client with MariaDB tools
- **Database connectivity** through private networking within VPC

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Multiple public subnets for RDS high availability
- DB subnet group spanning multiple AZs
- Security groups for database and client access

### Database
- **RDS MySQL Instance**: Configurable version and instance class
- **Multi-AZ Support**: Optional for high availability
- **Encrypted storage**: Configurable storage type and auto-scaling
- **Automated backups**: Configurable retention period
- **Private access**: Database accessible only within VPC

### Compute
- **EC2 Client Instance**: Amazon Linux 2023 with MySQL client tools
- **MariaDB Client**: Pre-installed for MySQL connectivity
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
   - MySQL database configuration (instance class, version, storage)
   - Multi-AZ and backup settings
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
| `01_variables.tf` | Variable definitions for MySQL and client |
| `02_provider.tf` | AWS provider configuration |
| `03_network.tf` | VPC and networking components |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key pair configuration |
| `06_rds_mysql.tf` | RDS MySQL database configuration |
| `07_instance_linux_al2.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection instructions |

## Usage

After deployment, Terraform will output SSH connection instructions, database endpoint, and password.

### SSH Access
```bash
# Connect to the MySQL client instance
ssh -i <private_key_path> ec2-user@<instance_public_ip>
```

### Database Connection
Once connected to the EC2 instance:

```bash
# Set password environment variable
export MYSQL_PWD="<generated_password>"

# Connect to MySQL database using the provided script
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

- Database in private subnets with no public access
- Security groups restricting access to MySQL port (3306)
- Auto-generated strong database password
- Encrypted EBS volumes
- VPC-only database connectivity

## MySQL Configuration

- **Engine**: MySQL (configurable version)
- **Instance Class**: Configurable (e.g., db.t3.micro)
- **Storage**: GP2/GP3 with auto-scaling support
- **Multi-AZ**: Optional for high availability
- **Backups**: Configurable retention period
- **Monitoring**: CloudWatch integration

## Cloud-Init Features

- **MariaDB Client**: Automatic installation for MySQL connectivity
- **Connection Script**: Ready-to-use database connection script
- **Network Tools**: nmap and other utilities installed

## Additional Scripts

- **Latency Testing**: Python script for database latency measurement
- **Network Scanning**: Shell script for network diagnostics

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- Database password is randomly generated and displayed in Terraform output
- MariaDB client is compatible with MySQL and automatically installed
- Database is accessible only from within the VPC for security
- Multi-AZ deployment provides automatic failover capability
- Perfect for MySQL database development and testing environments
- Consider enabling Multi-AZ and longer backup retention for production