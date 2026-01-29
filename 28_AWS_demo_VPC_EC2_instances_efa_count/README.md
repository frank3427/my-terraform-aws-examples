# AWS VPC with EFA-Enabled EC2 Instances Demo (NOT FINISHED)

⚠️ **This project is not finished and may not work as expected.**

This Terraform project demonstrates AWS infrastructure setup with VPC, EFA-enabled EC2 instances, and high-performance computing networking for HPC workloads.

## Architecture Overview

- **VPC** with public and private subnets
- **EFA-enabled EC2 instances** with dedicated EFA network interfaces
- **Cluster placement group** for optimal network performance
- **Dual network interfaces** per instance (standard + EFA)
- **Auto-generated SSH keys** for secure instance access

## Infrastructure Components

### Network
- VPC with configurable CIDR block
- Public subnet for standard network interfaces
- Private subnet for EFA network interfaces
- Dedicated security groups for EFA traffic

### Compute
- **EFA-Enabled Instances**: High-performance computing instances
- **Cluster Placement Group**: Instances placed for optimal network performance
- **Dual NICs**: Standard Ethernet + EFA interfaces per instance
- **Elastic IPs**: Persistent public IP addresses

### High-Performance Networking
- **EFA (Elastic Fabric Adapter)**: Low-latency, high-throughput networking
- **SR-IOV**: Single Root I/O Virtualization for network performance
- **Bypass Kernel**: Direct hardware access for minimal latency

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Understanding of HPC and EFA concepts
- EFA-supported instance types available in your region

## Setup Instructions

⚠️ **Warning: This configuration is incomplete and may not deploy successfully.**

1. **Clone and navigate to the project directory**

2. **Check EFA-supported instance types in your region**
   ```bash
   ./list_efa_instance_types_in_region.sh
   ```

3. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region
   - CIDR blocks for VPC and subnets
   - EFA-supported instance type
   - Number of instances
   - Private IP addresses for instances and EFA interfaces

4. **Initialize Terraform**
   ```bash
   terraform init
   ```

5. **Plan the deployment**
   ```bash
   terraform plan
   ```

6. **Deploy the infrastructure (at your own risk)**
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
| `06_instances_linux_EFA.tf` | EFA-enabled EC2 instances |

## Known Issues

- Configuration is incomplete (marked as NOT_FINISHED)
- EFA driver installation may be missing
- MPI or other HPC software configuration not included
- Network performance testing tools not configured
- Limited documentation for EFA setup

## EFA Features

This project attempts to demonstrate:
- **Low Latency**: Sub-microsecond latencies for HPC workloads
- **High Throughput**: Up to 100 Gbps network performance
- **Bypass Kernel**: Direct hardware access for minimal overhead
- **MPI Support**: Message Passing Interface for parallel computing
- **Cluster Networking**: Optimized for tightly-coupled workloads

## EFA-Supported Instance Types

Common EFA-supported instances include:
- **C5n**: Compute optimized with enhanced networking
- **M5n/M5dn**: General purpose with enhanced networking  
- **R5n/R5dn**: Memory optimized with enhanced networking
- **P3dn**: GPU instances for ML/HPC workloads
- **P4d**: Latest GPU instances with EFA support

## Potential HPC Operations

If properly configured, you could perform:
```bash
# Check EFA interface
fi_info -p efa

# Run MPI applications
mpirun -n <num_processes> --hostfile hosts <application>

# Network performance testing
efa_test -r <remote_host>

# Check EFA statistics
cat /sys/class/infiniband/*/ports/*/counters/*
```

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- This project is marked as NOT_FINISHED
- EFA requires specific instance types and proper driver installation
- Cluster placement groups ensure instances are physically close
- EFA is designed for HPC, ML, and high-performance workloads
- Consider completing EFA driver and MPI configuration
- EFA instances are more expensive than standard instances
- Network performance benefits require proper application design