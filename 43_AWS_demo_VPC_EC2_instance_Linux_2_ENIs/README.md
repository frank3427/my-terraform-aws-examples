# AWS VPC with EC2 Instance Linux 2 ENIs Demo

This Terraform project demonstrates AWS EC2 instance configuration with multiple Elastic Network Interfaces (ENIs), showcasing network segmentation and service isolation using separate network interfaces.

## Architecture Overview

- **VPC** with two public subnets in the same availability zone
- **EC2 Instance** with two ENIs for service separation
- **Primary ENI** for SSH access in first subnet
- **Secondary ENI** for HTTP web service in second subnet
- **Separate Security Groups** and Network ACLs for each ENI
- **Elastic IPs** for both network interfaces

## Infrastructure Components

### Network
- VPC with two public subnets in same AZ
- Internet gateway for public connectivity
- Two Network ACLs with different access rules
- Two Security Groups for service-specific access

### Compute
- **EC2 Instance**: Single instance with dual network interfaces
- **Primary ENI**: SSH access (port 22) in first subnet
- **Secondary ENI**: HTTP access (port 80) in second subnet
- **Encrypted EBS**: Root volume with GP3 storage

### Network Interfaces
- **Primary ENI**: Attached during instance launch
- **Secondary ENI**: Separately created and attached
- **Elastic IPs**: One for each network interface
- **Service Isolation**: Different subnets and security controls

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- Web browser for testing HTTP service

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zone
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for SSH/HTTP access
   - Instance type and private IP address
   - Linux distribution (Amazon Linux or Ubuntu)

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
| `03_network.tf` | VPC, subnets, and dual ENI networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key generation |
| `06_instance_linux.tf` | EC2 instance with dual ENI configuration |
| `07_outputs.tf` | Output values and connection instructions |
| `cloud_init/` | Instance initialization scripts |

## Usage

After deployment, access services through different ENIs:

### SSH Access (Primary ENI)
```bash
ssh -i <private-key-path> <username>@<PRIMARY-ENI-ELASTIC-IP>
```

### Web Access (Secondary ENI)
```bash
# Access web server via secondary ENI
http://<SECONDARY-ENI-ELASTIC-IP>
```

### Network Interface Testing
```bash
# From within the instance, check network interfaces
ip addr show
ip route show

# Test connectivity from each interface
curl --interface eth0 http://httpbin.org/ip
curl --interface eth1 http://httpbin.org/ip
```

## Multi-ENI Features

- **Service Isolation**: SSH and HTTP on separate network interfaces
- **Subnet Separation**: Each ENI in different subnet with specific ACLs
- **Security Segmentation**: Different security groups per ENI
- **Elastic IP Assignment**: Persistent public IPs for both interfaces
- **Independent Routing**: Each ENI can have different routing rules

## Network Segmentation

### Primary ENI (SSH)
- **Subnet**: demo43-public1-ssh
- **Security Group**: demo43-sg1 (SSH access only)
- **Network ACL**: demo43-acl1 (SSH and ephemeral ports)
- **Purpose**: Administrative access

### Secondary ENI (HTTP)
- **Subnet**: demo43-public2-http  
- **Security Group**: demo43-sg2 (HTTP access only)
- **Network ACL**: demo43-acl2 (HTTP access)
- **Purpose**: Web service delivery

## Security Features

- **Network Isolation**: Services separated at network interface level
- **Granular Access Control**: Different ACLs and security groups per ENI
- **Encrypted Storage**: EBS root volume encryption
- **IP-based Restrictions**: Authorized IP addresses for access
- **Service-Specific Rules**: Each ENI allows only required protocols

## Use Cases

- **Service Separation**: Isolate management and application traffic
- **Compliance Requirements**: Separate networks for different data types
- **Performance Optimization**: Dedicated interfaces for high-throughput services
- **Security Zones**: Different security policies per network interface
- **Multi-Tenant Applications**: Separate interfaces for different tenants

## Cloud-Init Scripts

- **Amazon Linux**: Installs Apache, configures web server
- **Ubuntu**: Alternative Linux distribution support
- **Web Server Setup**: Configures HTTP service on secondary interface
- **Network Configuration**: Ensures proper interface setup

## Monitoring

Check network interface status:
```bash
# View network interfaces
aws ec2 describe-network-interfaces --filters "Name=attachment.instance-id,Values=<INSTANCE-ID>"

# Monitor interface metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name NetworkIn \
  --dimensions Name=InstanceId,Value=<INSTANCE-ID> \
  --start-time <START> \
  --end-time <END> \
  --period 300 \
  --statistics Average
```

## Troubleshooting

Common multi-ENI issues:
- **Routing**: Ensure proper routing tables for each interface
- **Security Groups**: Verify correct security group assignments
- **Network ACLs**: Check ACL rules for each subnet
- **Source/Destination Check**: May need to disable for routing scenarios

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- Both ENIs are in the same AZ but different subnets
- Each ENI has its own Elastic IP for persistent addressing
- Network ACLs provide subnet-level security controls
- Security groups provide instance-level security controls
- This pattern is useful for service isolation and compliance requirements