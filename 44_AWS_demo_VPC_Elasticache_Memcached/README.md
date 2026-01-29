# AWS VPC with ElastiCache Memcached Demo

This Terraform project demonstrates AWS ElastiCache Memcached cluster deployment with VPC integration, showcasing in-memory caching capabilities for high-performance applications.

## Architecture Overview

- **VPC** with public and private subnets
- **ElastiCache Memcached Cluster** in private subnet for security
- **EC2 Instance** as client for testing Memcached connectivity
- **Subnet Group** for ElastiCache placement
- **Security Groups** for controlled access to cache cluster

## Infrastructure Components

### Network
- VPC with public subnet for EC2 instance
- Private subnet for ElastiCache cluster isolation
- Internet gateway and NAT gateway for connectivity
- Security groups for EC2 and Memcached access control

### Caching
- **ElastiCache Memcached Cluster**: High-performance in-memory cache
- **Multiple Cache Nodes**: Configurable number of cache nodes
- **Subnet Group**: Defines subnets for cache cluster placement
- **Parameter Group**: Default Memcached configuration

### Compute
- **EC2 Instance**: Client instance with Memcached tools
- **Elastic IP**: Persistent public IP for SSH access
- **Multi-OS Support**: Amazon Linux, Ubuntu, SLES, RHEL

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- Basic understanding of Memcached protocol

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zone
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for SSH access
   - ElastiCache node type and number of nodes
   - Memcached version
   - Linux OS version

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
| `06_instance_linux.tf` | EC2 instance with multi-OS support |
| `07_elasticache_memcached.tf` | ElastiCache Memcached cluster |
| `08_outputs.tf` | Output values and connection info |
| `cloud_init/` | OS-specific initialization scripts |

## Usage

After deployment, test the Memcached cluster:

### SSH Access
```bash
ssh -i <private-key-path> <username>@<ELASTIC-IP>
```

### Memcached Testing
```bash
# Install telnet for testing (if not already installed)
sudo yum install telnet -y  # Amazon Linux/RHEL
sudo apt install telnet -y  # Ubuntu

# Connect to Memcached cluster
telnet <MEMCACHED-ENDPOINT> 11211

# Basic Memcached commands
set mykey 0 3600 5
hello
get mykey
quit
```

### Application Integration
```bash
# Install Memcached client libraries
# Python
pip install python-memcached

# Node.js
npm install memcached

# PHP
sudo yum install php-pecl-memcached -y
```

## ElastiCache Features

- **High Performance**: Sub-millisecond latency for cache operations
- **Scalability**: Multiple cache nodes for increased capacity
- **Automatic Discovery**: Client libraries can discover all nodes
- **Multi-AZ Support**: Deploy across multiple availability zones
- **Monitoring**: CloudWatch metrics for performance monitoring

## Memcached Configuration

- **Engine Version**: Configurable Memcached version
- **Node Type**: Various instance types for different performance needs
- **Cache Nodes**: Horizontal scaling with multiple nodes
- **Port**: Standard Memcached port 11211
- **Parameter Group**: Default Memcached 1.6 configuration

## Security Features

- **Private Subnet**: Cache cluster isolated from internet
- **VPC Security**: Access restricted to VPC CIDR block
- **Security Groups**: Port-specific access control
- **Encrypted Storage**: EBS encryption for EC2 instance
- **Network Isolation**: Cache cluster not directly accessible

## Multi-OS Support

The project supports multiple Linux distributions:
- **Amazon Linux 2**: Default AWS Linux distribution
- **Amazon Linux 2023**: Latest AWS Linux version
- **Ubuntu 22**: Popular Ubuntu LTS version
- **SLES 15**: SUSE Linux Enterprise Server
- **RHEL 9**: Red Hat Enterprise Linux

## Cloud-Init Scripts

OS-specific initialization scripts:
- Install Memcached client tools
- Configure system packages
- Set up development environment
- Apply security updates

## Monitoring

Monitor ElastiCache performance:
```bash
# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name CurrConnections \
  --dimensions Name=CacheClusterId,Value=<CLUSTER-ID> \
  --start-time <START> \
  --end-time <END> \
  --period 300 \
  --statistics Average

# Cache node discovery
aws elasticache describe-cache-clusters \
  --cache-cluster-id <CLUSTER-ID> \
  --show-cache-node-info
```

## Performance Testing

Test cache performance:
```bash
# Using memcached-tool (if available)
memcached-tool <ENDPOINT>:11211 stats

# Using telnet for basic operations
echo -e "stats\nquit" | telnet <ENDPOINT> 11211
```

## Use Cases

- **Session Storage**: Web application session management
- **Database Caching**: Reduce database load with query caching
- **API Response Caching**: Cache frequently requested API responses
- **Real-time Analytics**: Store temporary computation results
- **Gaming Leaderboards**: High-speed leaderboard updates

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- ElastiCache cluster is deployed in private subnet for security
- Multiple cache nodes provide horizontal scaling
- Default parameter group is used for simplicity
- Security group allows access from entire VPC CIDR
- Elastic IP provides persistent access to EC2 instance