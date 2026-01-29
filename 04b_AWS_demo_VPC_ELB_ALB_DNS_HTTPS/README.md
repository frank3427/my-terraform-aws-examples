# Demo 04b: AWS VPC with ELB/ALB, DNS and HTTPS

This Terraform configuration creates a complete AWS infrastructure with VPC, Application Load Balancer (ALB), DNS configuration, and HTTPS support.

## Architecture

```
Internet -> Route 53 DNS -> ALB (HTTPS) -> WebServers (Private Subnets)
                            |
                         Bastion Host (Public Subnet)
```

## Resources Created

- **VPC** with public and private subnets across 2 availability zones
- **Internet Gateway** and **NAT Gateway** for connectivity
- **Bastion host** in public subnet for secure SSH access
- **2 Web servers** in private subnets behind ALB
- **Application Load Balancer (ALB)** with HTTPS termination
- **Route 53 DNS** configuration with SSL certificate
- **Auto-generated SSH keys** for secure access
- **Security Groups** with appropriate rules

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version 0.12+)
- Existing Route 53 hosted zone for DNS configuration

## Usage

1. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - Network CIDR blocks
   - Authorized IP addresses
   - DNS domain and zone ID

2. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Connect to instances**
   ```bash
   ssh -F sshcfg d04b-bastion    # Bastion host
   ssh -F sshcfg d04b-ws1        # Web server 1
   ssh -F sshcfg d04b-ws2        # Web server 2
   ```

4. **Access web application**
   Open `https://your-dns-name` in your browser

## Configuration Files

| File | Purpose |
|------|---------|
| `01_variables.tf` | Variable definitions |
| `02_provider.tf` | AWS provider configuration |
| `03_network.tf` | VPC, subnets, routing |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair_bastion.tf` | SSH key generation for bastion |
| `06_ssh_key_pair_websrv.tf` | SSH key generation for web servers |
| `07_ec2_instance_bastion.tf` | Bastion host configuration |
| `08_ec2_instances_websrv.tf` | Web server instances |
| `09_elb_alb.tf` | Application Load Balancer setup |
| `10_dns_and_cert.tf` | DNS and SSL configuration |
| `11_outputs.tf` | Output values and SSH configuration |

## Security Features

- Web servers isolated in private subnets
- Bastion host for secure SSH access
- Auto-generated SSH key pairs
- HTTPS with SSL certificate
- IP-based access restrictions

## Cleanup

```bash
terraform destroy
```