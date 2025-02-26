# Terraform AWS EC2 Instance Provisioning with Cloud-Init

This project provides Terraform configurations for provisioning EC2 instances on AWS with custom cloud-init scripts for different Linux distributions.

The repository contains Terraform files to set up the necessary AWS resources, including networking, security groups, and EC2 instances. It also includes cloud-init scripts for Amazon Linux, Red Hat Enterprise Linux (RHEL), SUSE Linux Enterprise Server (SLES), and Ubuntu, allowing for automated configuration of the instances upon launch.

Key features of this project include:

- Modular Terraform configuration for easy customization
- Support for multiple Linux distributions (Amazon Linux, RHEL, SLES, Ubuntu)
- Automated EBS volume attachment and filesystem creation
- Package installation and system updates as part of instance initialization
- Basic performance testing script creation (for Amazon Linux)

## Repository Structure

```
.
├── 01_variables.tf
├── 02_provider.tf
├── 03_network.tf
├── 04_data_sources.tf
├── 05_ssh_key_pair.tf
├── 06_instance_linux.tf
├── 07_ebs_volume.tf
├── 99_aws-whoami.tf
└── cloud_init/
    ├── cloud_init_al.sh
    ├── cloud_init_rhel.sh
    ├── cloud_init_sles.sh
    └── cloud_init_ubuntu.sh
```

- Terraform configuration files (\*.tf): Define AWS resources and their configurations
- `cloud_init/`: Contains distribution-specific cloud-init scripts for instance initialization

## Usage Instructions

### Prerequisites

- Terraform v0.12.0 or later
- AWS CLI configured with appropriate credentials
- Basic understanding of AWS services and Terraform

### Installation

1. Clone the repository:

   ```
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Initialize Terraform:

   ```
   terraform init
   ```

3. Review and modify the variables in `terraform.tfvars` as needed.

4. Plan the Terraform execution:

   ```
   terraform plan
   ```

5. Apply the Terraform configuration:
   ```
   terraform apply
   ```

### Configuration

The main configuration options are defined in `01_variables.tf`. You can modify these variables to customize your deployment, including:

- AWS region
- VPC and subnet configurations
- EC2 instance type and AMI
- EBS volume size

### Cloud-Init Scripts

The `cloud_init/` directory contains distribution-specific initialization scripts:

- `cloud_init_al.sh`: Amazon Linux
- `cloud_init_rhel.sh`: Red Hat Enterprise Linux
- `cloud_init_sles.sh`: SUSE Linux Enterprise Server
- `cloud_init_ubuntu.sh`: Ubuntu

These scripts perform the following common tasks:

- Create an XFS filesystem on the additional EBS volume
- Mount the EBS volume to `/mnt/ebs1`
- Install packages like `zsh` and `nmap`
- Update system packages

The Amazon Linux script additionally installs Docker and creates a basic performance test script.

### Troubleshooting

1. EBS Volume Not Attached

   - Problem: The additional EBS volume is not visible in the instance
   - Diagnostic steps:
     1. Check the AWS Console to ensure the volume is created and attached
     2. SSH into the instance and run `lsblk` to list block devices
   - Solution: If the volume is not listed, detach and reattach it using the AWS Console or CLI

2. Cloud-Init Script Execution Issues

   - Problem: Cloud-init script doesn't seem to have executed properly
   - Diagnostic steps:
     1. SSH into the instance
     2. Check the cloud-init log: `sudo cat /var/log/cloud-init.log`
     3. Check the custom log: `sudo cat /var/log/cloud-init2.log`
   - Solution: Review the logs for errors and adjust the cloud-init script accordingly

3. Package Installation Failures
   - Problem: Packages fail to install during instance initialization
   - Diagnostic steps:
     1. Check the cloud-init logs as described above
     2. Verify internet connectivity from the instance
   - Solution: Ensure the instance has internet access through a NAT Gateway or Internet Gateway

### Debugging

To enable verbose logging for Terraform:

```
export TF_LOG=DEBUG
terraform apply
```

For more detailed AWS API calls, you can enable AWS CLI debug mode:

```
export AWS_DEBUG=true
```

Log files are typically located at:

- Terraform: `terraform.log` in the current directory
- Cloud-init: `/var/log/cloud-init.log` and `/var/log/cloud-init2.log` on the EC2 instance

## Data Flow

The data flow in this Terraform configuration follows these steps:

1. Terraform reads the configuration files and variables.
2. It initializes the AWS provider using the specified region and credentials.
3. Network resources (VPC, subnets, etc.) are created or referenced.
4. Data sources are queried to fetch existing AWS resource information.
5. An SSH key pair is created or imported for EC2 instance access.
6. EC2 instances are launched with the specified AMI and instance type.
7. EBS volumes are created and attached to the EC2 instances.
8. Cloud-init scripts are passed to the instances for initialization.

```
[Variables] -> [Provider] -> [Network] -> [Data Sources]
                                |
                                v
[SSH Key Pair] <- [EC2 Instance] <- [EBS Volume]
                        |
                        v
                [Cloud-Init Script]
```

Note: The `99_aws-whoami.tf` file contains outputs to display information about the AWS account being used.

## Infrastructure

The infrastructure is defined using Terraform and includes the following key resources:

### VPC and Networking

- VPC (defined in `03_network.tf`)
- Subnets
- Internet Gateway
- Route Tables

### EC2 Resources

- EC2 Instances (defined in `06_instance_linux.tf`)
- EBS Volumes (defined in `07_ebs_volume.tf`)
- Security Groups

### IAM and Security

- SSH Key Pair (defined in `05_ssh_key_pair.tf`)

### Data Sources

- Various AWS data sources (defined in `04_data_sources.tf`)

Each resource is configured with specific settings such as CIDR blocks, instance types, and volume sizes, which can be customized through variables defined in `01_variables.tf`.
