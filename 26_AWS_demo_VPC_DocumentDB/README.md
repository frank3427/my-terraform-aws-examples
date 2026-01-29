# AWS VPC with DocumentDB Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, Amazon DocumentDB (MongoDB-compatible), and EC2 client instance for database connectivity.

## Architecture Overview

- **VPC** with public subnets across multiple availability zones
- **Amazon DocumentDB cluster** with MongoDB-compatible API
- **EC2 instance** with MongoDB shell for database access
- **Auto-generated passwords** for secure database authentication
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnets across multiple availability zones for DocumentDB
- Subnet group for DocumentDB cluster placement

### Database
- **DocumentDB Cluster**: MongoDB-compatible managed database
- **DocumentDB Instances**: Configurable number of database instances
- **Security Groups**: Database access control
- **Encryption**: Storage encryption enabled
- **Backup**: Automated backup configuration

### Compute
- **EC2 Instance**: Amazon Linux 2 with MongoDB shell pre-installed
- **Connection Script**: Ready-to-use DocumentDB connection script

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Basic MongoDB/DocumentDB knowledge

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for SSH access
   - DocumentDB configuration (instance type, number of instances)

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
| `03_network.tf` | VPC, subnets, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key generation |
| `06_documentDB.tf` | DocumentDB cluster and instances |
| `07_instance_linux_al2.tf` | EC2 client instance |
| `08_outputs.tf` | Output values and connection info |

## Usage

After deployment, wait a few minutes for the DocumentDB cluster to be ready, then:

### SSH Access
```bash
ssh -i sshkeys_generated/ssh_key_demo26.priv ec2-user@<INSTANCE-PUBLIC-IP>
```

### DocumentDB Connection
```bash
# Connect to DocumentDB using the pre-configured script
./docdb.sh

# Or connect manually with mongosh
mongosh --tls \
        --tlsCAFile /home/ec2-user/global-bundle.pem \
        --authenticationDatabase admin \
        --username <USERNAME> \
        --password <PASSWORD> \
        "mongodb://<CLUSTER-ENDPOINT>:27017?retryWrites=false"
```

### Basic DocumentDB Operations
```javascript
// Show databases
show dbs

// Create and use a database
use myapp

// Insert a document
db.users.insertOne({name: "John", email: "john@example.com"})

// Find documents
db.users.find()

// Create an index
db.users.createIndex({email: 1})
```

## Security Features

- DocumentDB cluster in private subnets with VPC security groups
- Storage encryption enabled by default
- Auto-generated strong passwords
- TLS/SSL encryption for client connections
- Auto-generated SSH key pairs
- IP-based access restrictions

## DocumentDB Features

- **MongoDB Compatibility**: Supports MongoDB 3.6+ API
- **Managed Service**: Automated backups, patching, and monitoring
- **High Availability**: Multi-AZ deployment support
- **Scalability**: Easy horizontal and vertical scaling
- **Security**: VPC isolation, encryption at rest and in transit
- **Backup & Recovery**: Point-in-time recovery capabilities

## Cloud-Init Scripts

- Downloads DocumentDB CA certificate for TLS connections
- Installs MongoDB shell (mongosh)
- Creates connection script with cluster credentials
- Sets up proper file permissions

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- DocumentDB password is randomly generated and shown in Terraform outputs
- TLS certificate is required for DocumentDB connections
- DocumentDB is compatible with MongoDB 3.6+ drivers and tools
- Cluster creation takes several minutes to complete
- Consider using AWS Secrets Manager for production password management