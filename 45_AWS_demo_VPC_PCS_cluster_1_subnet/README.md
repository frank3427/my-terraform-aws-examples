# AWS VPC with PCS Cluster 1 Subnet Demo

This Terraform project demonstrates AWS Parallel Computing Service (PCS) cluster deployment with SLURM scheduler, showcasing high-performance computing (HPC) capabilities with shared storage systems.

## Architecture Overview

- **VPC** with public subnet for PCS cluster deployment
- **PCS Cluster** with SLURM scheduler for job management
- **Compute Node Group** with configurable instance types and scaling
- **SLURM Queue** for job submission and execution
- **EFS File System** for shared storage across compute nodes
- **FSx Lustre** for high-performance parallel file system
- **Launch Templates** for compute node configuration

## Infrastructure Components

### High-Performance Computing
- **PCS Cluster**: Managed SLURM cluster with configurable size
- **Compute Node Group**: Auto-scaling compute nodes
- **SLURM Queue**: Job queue for workload management
- **Launch Templates**: Custom EC2 configurations for compute nodes

### Storage Systems
- **EFS File System**: Network-attached storage for shared data
- **FSx Lustre**: High-performance parallel file system
- **Encrypted Storage**: Both EFS and FSx with encryption at rest

### Network & Security
- **VPC**: Isolated network environment
- **Public Subnet**: Single subnet deployment for simplicity
- **Security Groups**: Controlled access for cluster communication
- **IAM Roles**: Instance profiles for PCS service permissions

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Understanding of SLURM workload manager
- Basic knowledge of HPC concepts
- Sufficient AWS service limits for compute instances

## Setup Instructions

1. **Clone and navigate to the project directory**

2. **Configure variables**
   ```bash
   cp terraform.tfvars.TEMPLATE terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - AWS region and availability zone
   - CIDR blocks for VPC and subnet
   - PCS cluster configuration
   - Compute node instance types and counts
   - Storage system sizes
   - SLURM queue name

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
| `05_ssh_key_pairs.tf` | SSH keys for login and compute nodes |
| `06_storage_efs.tf` | EFS file system configuration |
| `07_storage_lustre.tf` | FSx Lustre file system |
| `08_ec2_launch_templates.tf` | Launch templates for compute nodes |
| `09_ec2_instance_profiles.tf` | IAM roles and instance profiles |
| `10_pcs_cluster_and_nodes.tf` | PCS cluster, compute nodes, and queue |
| `11_outputs.tf` | Output values and connection info |
| `cloud_init/` | Node initialization templates |
| `slurm_scripts/` | Sample SLURM job scripts |
| `templates/` | Configuration templates |

## Usage

After deployment, access and use the PCS cluster:

### Cluster Access
```bash
# Connect to cluster login node (via AWS Console or CLI)
aws pcs describe-cluster --cluster-id <CLUSTER-ID>

# Submit SLURM jobs
sbatch test_job.sh
squeue
sinfo
```

### SLURM Commands
```bash
# View cluster information
sinfo -N -l

# Submit a job
sbatch --job-name=test --time=00:10:00 --ntasks=4 test_script.sh

# Monitor jobs
squeue -u $USER
sacct

# Cancel a job
scancel <JOB-ID>
```

### Storage Access
```bash
# EFS mount point (typically /shared)
ls -la /shared/

# FSx Lustre mount point (typically /lustre)
ls -la /lustre/
```

## PCS Features

- **Managed SLURM**: Fully managed SLURM scheduler
- **Auto Scaling**: Dynamic compute node scaling
- **Multi-Instance Types**: Support for various EC2 instance types
- **Integrated Storage**: Built-in EFS and FSx Lustre integration
- **Job Scheduling**: Advanced job queuing and resource allocation

## SLURM Configuration

- **Scheduler Version**: SLURM 24.05
- **Cluster Size**: Configurable (SMALL, MEDIUM, LARGE)
- **Queue Management**: Custom queue configuration
- **Node Groups**: Flexible compute node group definitions
- **Scaling**: Min/max instance count configuration

## Storage Systems

### EFS (Elastic File System)
- **Performance Mode**: General Purpose
- **Throughput Mode**: Bursting
- **Encryption**: Enabled at rest
- **Use Case**: Shared application data and home directories

### FSx Lustre
- **Deployment Type**: PERSISTENT_2
- **Compression**: LZ4 data compression
- **Throughput**: 125 MB/s per TiB
- **Use Case**: High-performance parallel workloads

## Security Features

- **VPC Isolation**: Cluster deployed in private network
- **Security Groups**: Controlled inter-node communication
- **IAM Roles**: Least privilege access for compute nodes
- **Encrypted Storage**: Both EFS and FSx with encryption
- **SSH Key Management**: Separate keys for different node types

## Monitoring

Monitor cluster performance:
```bash
# SLURM cluster status
sinfo
squeue
sacct

# AWS CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/PCS \
  --metric-name RunningJobs \
  --dimensions Name=ClusterName,Value=<CLUSTER-NAME> \
  --start-time <START> \
  --end-time <END> \
  --period 300 \
  --statistics Average
```

## Sample Workloads

Example SLURM job script:
```bash
#!/bin/bash
#SBATCH --job-name=test_job
#SBATCH --time=00:30:00
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G

# Load modules
module load gcc

# Run parallel application
mpirun -np $SLURM_NTASKS ./my_application
```

## Cost Optimization

- **Spot Instances**: Consider using spot instances for compute nodes
- **Auto Scaling**: Configure appropriate min/max instance counts
- **Storage Optimization**: Choose appropriate storage types and sizes
- **Instance Types**: Select cost-effective instance types for workloads

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Notes

- SSH keys are automatically generated in the `sshkeys_generated/` directory
- PCS cluster creation takes 5-10 minutes
- Compute nodes auto-scale based on job queue
- EFS and FSx Lustre are automatically mounted on compute nodes
- SLURM configuration is managed by AWS PCS service
- Templates directory contains configuration files for cluster setup