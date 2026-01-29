# AWS VPC with CloudFront and ALB Demo

This Terraform project demonstrates a global content delivery architecture using AWS CloudFront CDN with Application Load Balancer (ALB) origin, providing high performance and security for web applications.

## Architecture Overview

- **VPC** with public and private subnets across multiple availability zones
- **Application Load Balancer** serving web content from multiple instances
- **CloudFront Distribution** for global content delivery and caching
- **Bastion Host** for secure SSH access to private instances
- **Web Servers** in private subnets behind ALB
- **S3 Bucket** for CloudFront access logs

## Infrastructure Components

### Network
- VPC with public subnets for ALB and bastion host
- Private subnets for web servers across multiple AZs
- Internet gateway and NAT gateway for connectivity
- Security groups with CloudFront-specific access controls

### Compute
- **Bastion Host**: Secure jump server for SSH access
- **Web Servers**: Apache HTTP servers in private subnets
- **Application Load Balancer**: HTTP load balancing with custom header validation

### Content Delivery
- **CloudFront Distribution**: Global CDN with ALB as origin
- **Custom Origin Configuration**: HTTP-only communication with ALB
- **Cache Behaviors**: Optimized caching for web content
- **Access Logging**: CloudFront logs stored in S3

### Security
- **Custom Header Validation**: Prevents direct ALB access
- **CloudFront-Only Access**: ALB restricted to CloudFront IP ranges
- **HTTPS Redirect**: Automatic HTTP to HTTPS redirection
- **S3 Bucket Security**: Private bucket with proper access controls

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- Domain name (optional) for custom CloudFront domain

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
| `03_network.tf` | VPC, subnets, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair_bastion.tf` | SSH key for bastion host |
| `06_ssh_key_pair_websrv.tf` | SSH key for web servers |
| `07_ec2_instance_bastion.tf` | Bastion host configuration |
| `08_ec2_instances_websrv.tf` | Web server instances |
| `09_elb_alb.tf` | Application Load Balancer with security |
| `10_cloudfront.tf` | CloudFront distribution and S3 logging |
| `11_outputs.tf` | Output values and access URLs |

## Usage

After deployment, access your application through CloudFront:

### Web Access
```bash
# Access via CloudFront (recommended)
https://<CLOUDFRONT-DOMAIN-NAME>

# Direct ALB access (will be blocked)
http://<ALB-DNS-NAME>
```

### SSH Access
```bash
# Connect to bastion host
ssh -F sshcfg d40-bastion

# Connect to web servers through bastion
ssh -F sshcfg d40-ws1
ssh -F sshcfg d40-ws2
```

## CloudFront Features

- **Global Edge Locations**: Content cached worldwide for low latency
- **HTTPS Redirect**: Automatic HTTP to HTTPS redirection
- **IPv6 Support**: Dual-stack IPv4/IPv6 connectivity
- **Custom Caching**: Configurable TTL values for optimal performance
- **Access Logging**: Detailed request logs stored in S3

## Security Features

- **Origin Protection**: ALB only accepts traffic from CloudFront
- **Custom Header Validation**: Secret header prevents direct ALB access
- **CloudFront IP Restriction**: Security group limits ALB access
- **Private Web Servers**: Instances in private subnets
- **S3 Bucket Security**: Private logging bucket with proper policies

## ALB Configuration

- **Custom Header Check**: Validates `X-Origin-Verify` header
- **Target Group**: Health checks for web server instances
- **Security Group**: Restricted to CloudFront IP ranges
- **Fixed Response**: Returns 403 for invalid requests

## Monitoring

View CloudFront logs:
```bash
aws s3 ls s3://<CLOUDFRONT-LOGS-BUCKET>/cloudfront-logs/
aws s3 cp s3://<CLOUDFRONT-LOGS-BUCKET>/cloudfront-logs/<LOG-FILE> .
```

Monitor ALB metrics:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=<ALB-ARN-SUFFIX> \
  --start-time <START> \
  --end-time <END> \
  --period 300 \
  --statistics Sum
```

## Performance Benefits

- **Global Caching**: Reduced latency through edge locations
- **Origin Offloading**: CloudFront serves cached content
- **Compression**: Automatic gzip compression
- **HTTP/2 Support**: Modern protocol support
- **SSL Termination**: HTTPS handled at edge locations

## Cost Optimization

- **Price Class 100**: Uses only North America and Europe edge locations
- **Efficient Caching**: Reduces origin requests
- **S3 Logging**: Cost-effective log storage
- **Auto Scaling**: ALB distributes load efficiently

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- CloudFront distribution deployment takes 15-20 minutes
- Custom header secret is randomly generated for security
- S3 bucket for logs is created with secure default settings
- Direct ALB access is blocked by design for security