# AWS VPC with Global Accelerator and Private ALB Demo

This Terraform project demonstrates AWS Global Accelerator with a private Application Load Balancer, providing improved global performance and availability for web applications through AWS's global network.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **Private ALB** in private subnets serving web content
- **Public ALB** for comparison and testing
- **Global Accelerator** providing global anycast IP addresses
- **Bastion Host** for secure SSH access to private instances
- **Web Servers** in private subnets behind private ALB
- **Test Instance** in separate VPC for connectivity testing

## Infrastructure Components

### Network
- Main VPC with public and private subnets across multiple AZs
- Test VPC for connectivity validation
- Internet gateway and NAT gateway for connectivity
- Security groups for ALB, web servers, and bastion access

### Compute
- **Bastion Host**: Secure jump server for SSH access
- **Web Servers**: Apache HTTP servers in private subnets
- **Test Instance**: Separate VPC instance for testing connectivity
- **Private ALB**: Internal load balancer in private subnets
- **Public ALB**: Internet-facing load balancer for comparison

### Global Acceleration
- **Global Accelerator**: Anycast IP addresses for improved performance
- **Listener Configuration**: TCP listener on port 80
- **Endpoint Group**: Private ALB as target endpoint
- **Client IP Preservation**: Maintains original client IP addresses

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- Understanding of Global Accelerator pricing (charges apply)

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zones
   - CIDR blocks for VPC and subnets
   - Authorized IP addresses for SSH access
   - Number of web server instances

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
| `03_network.tf` | Main VPC, subnets, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair_bastion.tf` | SSH key for bastion host |
| `06_ssh_key_pair_websrv.tf` | SSH key for web servers |
| `07_ec2_instance_bastion.tf` | Bastion host configuration |
| `08_ec2_instances_websrv.tf` | Web server instances |
| `09_elb_alb_private.tf` | Private ALB with custom header validation |
| `10_elb_alb_public.tf` | Public ALB for comparison |
| `11_global_accelerator.tf` | Global Accelerator configuration |
| `21_test_network.tf` | Test VPC and networking |
| `22_test_data_sources.tf` | Test VPC data sources |
| `23_test_ssh_key_pair.tf` | SSH key for test instance |
| `24_test_ec2_instance.tf` | Test instance configuration |
| `31_outputs.tf` | Output values and access URLs |

## Usage

After deployment, test the different access methods:

### Global Accelerator Access
```bash
# Access via Global Accelerator (recommended)
curl http://<GLOBAL-ACCELERATOR-IP>

# Test from different global locations for performance comparison
```

### Direct ALB Access
```bash
# Public ALB (for comparison)
curl http://<PUBLIC-ALB-DNS-NAME>

# Private ALB (only accessible from within VPC)
# Connect to bastion first, then test private ALB
```

### SSH Access
```bash
# Connect to bastion host
ssh -F sshcfg d41-bastion

# Connect to web servers through bastion
ssh -F sshcfg d41-ws1
ssh -F sshcfg d41-ws2

# Connect to test instance
ssh -F sshcfg d41-test
```

## Global Accelerator Features

- **Anycast IP Addresses**: Two static IP addresses for global access
- **AWS Global Network**: Traffic routed through AWS backbone
- **Health Checks**: Automatic failover for unhealthy endpoints
- **Client IP Preservation**: Original client IP maintained
- **TCP/UDP Support**: Layer 4 load balancing capabilities

## Performance Benefits

- **Reduced Latency**: Traffic enters AWS network at nearest edge location
- **Improved Availability**: Automatic failover between healthy endpoints
- **Better Performance**: AWS global network optimization
- **DDoS Protection**: Built-in DDoS mitigation
- **Consistent Performance**: Stable performance regardless of user location

## Security Features

- **Private ALB**: Load balancer not directly accessible from internet
- **Custom Header Validation**: Secret header prevents unauthorized access
- **VPC Isolation**: Web servers in private subnets
- **Security Groups**: Layered security controls
- **Client IP Preservation**: Enables proper logging and security controls

## Testing Architecture

- **Test VPC**: Separate VPC for connectivity validation
- **Cross-VPC Testing**: Validates Global Accelerator connectivity
- **Performance Comparison**: Compare Global Accelerator vs direct ALB access
- **Latency Testing**: Measure performance improvements

## Monitoring

Test Global Accelerator performance:
```bash
# From test instance, compare latency
time curl http://<GLOBAL-ACCELERATOR-IP>
time curl http://<PUBLIC-ALB-DNS-NAME>

# Test from different regions for global performance
```

Monitor Global Accelerator metrics:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/GlobalAccelerator \
  --metric-name NewFlowCount \
  --dimensions Name=Accelerator,Value=<ACCELERATOR-ARN> \
  --start-time <START> \
  --end-time <END> \
  --period 300 \
  --statistics Sum
```

## Cost Considerations

- **Global Accelerator Charges**: Fixed hourly fee plus data transfer
- **Cross-AZ Traffic**: Charges for traffic between availability zones
- **Data Transfer**: Standard AWS data transfer rates apply
- **ALB Charges**: Standard Application Load Balancer pricing

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- Global Accelerator takes 5-10 minutes to provision
- Custom header secret is randomly generated for security
- Test VPC provides isolated environment for connectivity testing
- Client IP preservation requires compatible target types