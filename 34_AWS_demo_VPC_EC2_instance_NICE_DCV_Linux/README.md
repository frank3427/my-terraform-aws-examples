# AWS VPC with EC2 Instance and NICE DCV Linux Demo

This Terraform project demonstrates AWS infrastructure setup with VPC, EC2 instance, and NICE DCV remote desktop server for Linux graphical applications.

## Architecture Overview

- **VPC** with public subnet for internet access
- **EC2 Instance** with NICE DCV server for remote desktop access
- **Elastic IP** for persistent public IP address
- **Auto-generated SSH keys** for secure instance access
- **Random passwords** for DCV user authentication

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet with internet gateway
- Security group allowing SSH and NICE DCV access

### Compute
- **EC2 Instance**: Amazon Linux 2 with NICE DCV server
- **Elastic IP**: Persistent public IP across stop/start cycles
- **Encrypted EBS**: Root volume with GP3 storage

### Remote Desktop
- NICE DCV server for graphical remote desktop access
- Web-based client accessible via HTTPS
- Support for multiple concurrent user sessions
- GPU acceleration support (if GPU instance type used)

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH client for connecting to instances
- Web browser for NICE DCV web client access

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zone
   - CIDR blocks for VPC and subnet
   - Authorized IP addresses for SSH/DCV access
   - Instance type (consider GPU instances for graphics workloads)
   - Private IP address for the instance

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
| `03_network.tf` | VPC, subnet, and networking |
| `04_data_sources.tf` | AWS data sources |
| `05_ssh_key_pair.tf` | SSH key generation |
| `06_instance_linux_NiceDCV.tf` | EC2 instance with NICE DCV |
| `cloud_init/cloud_init_al2.sh` | Instance initialization script |

## Usage

After deployment, Terraform will output detailed connection instructions:

### SSH Access
```bash
ssh -i <private-key-path> ec2-user@<ELASTIC-IP>
```

### NICE DCV Setup Commands
```bash
# Set password for ec2-user
printf "<password>" | sudo passwd -f ec2-user --stdin

# Create DCV session for ec2-user
dcv create-session 1

# Create additional user and session
sudo useradd chris
printf "<password2>" | sudo passwd -f chris --stdin
sudo dcv create-session 2 --user chris --owner chris

# List active sessions
sudo dcv list-sessions
```

### Web Access
- Session 1: `https://<ELASTIC-IP>:8443/#1`
- Session 2: `https://<ELASTIC-IP>:8443/#2`

## NICE DCV Features

- **Web Client**: Browser-based remote desktop access
- **Multiple Sessions**: Support for concurrent user sessions
- **GPU Acceleration**: Hardware-accelerated graphics (with GPU instances)
- **Cross-Platform**: Works on Windows, macOS, and Linux clients
- **Secure**: HTTPS encryption for remote connections

## Security Features

- Encrypted EBS root volume
- Security groups with IP-based access restrictions
- Auto-generated SSH key pairs
- Randomly generated user passwords
- HTTPS encryption for DCV connections

## Cloud-Init Scripts

- **Amazon Linux 2**: Installs basic tools, Docker, and performance test scripts
- **Package Installation**: zsh, nmap, and Docker
- **User Configuration**: Docker group membership for ec2-user

## GPU Support

For graphics-intensive workloads, consider using GPU-enabled instance types:
- `g4dn.xlarge` - NVIDIA T4 GPU
- `g4ad.xlarge` - AMD Radeon Pro V520 GPU
- `g5.xlarge` - NVIDIA A10G GPU

## Monitoring

Check NICE DCV installation:
```bash
sudo dcvgldiag
```

List NVIDIA GPUs (if GPU instance):
```bash
nvidia-smi
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- User passwords are randomly generated and displayed in Terraform output
- Self-signed certificates cause browser security warnings
- NICE DCV sessions persist across SSH disconnections
- The Elastic IP ensures consistent access after instance restarts