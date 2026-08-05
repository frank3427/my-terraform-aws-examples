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

| File                        | Purpose                      |
| --------------------------- | ---------------------------- |
| `01_variables.tf`           | Variable definitions         |
| `02_provider.tf`            | AWS provider configuration   |
| `03_network.tf`             | VPC, subnets, and networking |
| `04_data_sources.tf`        | AWS data sources             |
| `05_ssh_key_pair.tf`        | SSH key generation           |
| `06_instances_linux_EFA.tf` | EFA-enabled EC2 instances    |

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

## Complete List of EC2 Instance Types Supporting EFA

> **Note:** This list was retrieved from the [AWS documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa.html) on June 27, 2026. It may change over time as AWS adds new instance types. Use the following AWS CLI command to get the current list for your region:
>
> ```bash
> aws ec2 describe-instance-types \
>     --region us-east-1 \
>     --filters Name=network-info.efa-supported,Values=true \
>     --query "InstanceTypes[*].[InstanceType]" \
>     --output text | sort
> ```

### Nitro v6 (EFA v4) — RDMA read & write supported

#### General Purpose

- m8a.48xlarge, m8a.metal-48xl
- m8azn.24xlarge, m8azn.metal-24xl
- m8gb.16xlarge, m8gb.24xlarge, m8gb.48xlarge, m8gb.metal-24xl, m8gb.metal-48xl
- m8gn.16xlarge, m8gn.24xlarge, m8gn.48xlarge, m8gn.metal-24xl, m8gn.metal-48xl
- m8i.48xlarge, m8i.96xlarge, m8i.metal-48xl, m8i.metal-96xl
- m8id.48xlarge, m8id.96xlarge, m8id.metal-48xl, m8id.metal-96xl
- m8in.48xlarge, m8in.96xlarge, m8in.metal-48xl, m8in.metal-96xl
- m8idn.48xlarge, m8idn.96xlarge, m8idn.metal-48xl, m8idn.metal-96xl
- m8ib.48xlarge, m8ib.96xlarge, m8ib.metal-48xl, m8ib.metal-96xl
- m8idb.48xlarge, m8idb.96xlarge, m8idb.metal-48xl, m8idb.metal-96xl
- m9g.48xlarge, m9g.metal-48xl
- m9gd.48xlarge, m9gd.metal-48xl

#### Compute Optimized

- c8a.48xlarge, c8a.metal-48xl
- c8gb.16xlarge, c8gb.24xlarge, c8gb.48xlarge, c8gb.metal-24xl, c8gb.metal-48xl
- c8gn.16xlarge, c8gn.24xlarge, c8gn.48xlarge, c8gn.metal-24xl, c8gn.metal-48xl
- c8i.48xlarge, c8i.96xlarge, c8i.metal-48xl, c8i.metal-96xl
- c8id.48xlarge, c8id.96xlarge, c8id.metal-48xl, c8id.metal-96xl
- c8in.48xlarge, c8in.96xlarge, c8in.metal-48xl, c8in.metal-96xl
- c8ib.48xlarge, c8ib.96xlarge, c8ib.metal-48xl, c8ib.metal-96xl

#### Memory Optimized

- r8a.48xlarge, r8a.metal-48xl
- r8gb.16xlarge, r8gb.24xlarge, r8gb.48xlarge, r8gb.metal-24xl, r8gb.metal-48xl
- r8gn.16xlarge, r8gn.24xlarge, r8gn.48xlarge, r8gn.metal-24xl, r8gn.metal-48xl
- r8i.48xlarge, r8i.96xlarge, r8i.metal-48xl, r8i.metal-96xl
- r8id.48xlarge, r8id.96xlarge, r8id.metal-48xl, r8id.metal-96xl
- r8in.48xlarge, r8in.96xlarge, r8in.metal-48xl, r8in.metal-96xl
- r8idn.48xlarge, r8idn.96xlarge, r8idn.metal-48xl, r8idn.metal-96xl
- r8ib.48xlarge, r8ib.96xlarge, r8ib.metal-48xl, r8ib.metal-96xl
- r8idb.48xlarge, r8idb.96xlarge, r8idb.metal-48xl, r8idb.metal-96xl
- x8aedz.24xlarge, x8aedz.metal-24xl
- x8i.48xlarge, x8i.64xlarge, x8i.96xlarge, x8i.metal-48xl, x8i.metal-96xl

#### Storage Optimized

- i8ge.48xlarge, i8ge.metal-48xl

#### Accelerated Computing

- g7.8xlarge, g7.12xlarge, g7.24xlarge, g7.48xlarge
- g7e.8xlarge, g7e.12xlarge, g7e.24xlarge, g7e.48xlarge
- p6-b200.48xlarge, p6-b300.48xlarge

#### High Performance Computing

- hpc8a.96xlarge

---

### Nitro v5 (EFA v3) — RDMA read & write supported (unless noted)

#### General Purpose

- m8g.24xlarge, m8g.48xlarge, m8g.metal-24xl, m8g.metal-48xl
- m8gd.24xlarge, m8gd.48xlarge, m8gd.metal-24xl, m8gd.metal-48xl

#### Compute Optimized

- c7gn.16xlarge, c7gn.metal _(RDMA read only, no write)_
- c8g.24xlarge, c8g.48xlarge, c8g.metal-24xl, c8g.metal-48xl
- c8gd.24xlarge, c8gd.48xlarge, c8gd.metal-24xl, c8gd.metal-48xl

#### Memory Optimized

- r8g.24xlarge, r8g.48xlarge, r8g.metal-24xl, r8g.metal-48xl
- r8gd.24xlarge, r8gd.48xlarge, r8gd.metal-24xl, r8gd.metal-48xl
- x8g.24xlarge, x8g.48xlarge, x8g.metal-24xl, x8g.metal-48xl

#### Storage Optimized

- i7ie.48xlarge, i7ie.metal-48xl
- i8g.48xlarge, i8g.metal-48xl

#### Accelerated Computing

- p5en.48xlarge
- p6e-gb200.36xlarge
- trn2.3xlarge, trn2.48xlarge, trn2u.48xlarge

#### High Performance Computing

- hpc7g.4xlarge, hpc7g.8xlarge, hpc7g.16xlarge _(RDMA read only, no write)_

---

### Nitro v4 (EFA v2) — RDMA read & write supported

#### General Purpose

- m6a.48xlarge, m6a.metal
- m6i.32xlarge, m6i.metal
- m6id.32xlarge, m6id.metal
- m6idn.32xlarge, m6idn.metal
- m6in.32xlarge, m6in.metal
- m7a.48xlarge, m7a.metal-48xl
- m7g.16xlarge, m7g.metal
- m7gd.16xlarge, m7gd.metal
- m7i.48xlarge, m7i.metal-48xl

#### Compute Optimized

- c6a.48xlarge, c6a.metal
- c6gn.16xlarge
- c6i.32xlarge, c6i.metal
- c6id.32xlarge, c6id.metal
- c6in.32xlarge, c6in.metal
- c7a.48xlarge, c7a.metal-48xl
- c7g.16xlarge, c7g.metal
- c7gd.16xlarge, c7gd.metal
- c7i.48xlarge, c7i.metal-48xl

#### Memory Optimized

- r6a.48xlarge, r6a.metal
- r6i.32xlarge, r6i.metal
- r6id.32xlarge, r6id.metal
- r6idn.32xlarge, r6idn.metal
- r6in.32xlarge, r6in.metal
- r7a.48xlarge, r7a.metal-48xl
- r7g.16xlarge, r7g.metal
- r7gd.16xlarge, r7gd.metal
- r7i.48xlarge, r7i.metal-48xl
- r7iz.32xlarge, r7iz.metal-32xl
- u7i-6tb.112xlarge, u7i-8tb.112xlarge, u7i-12tb.224xlarge
- u7in-16tb.224xlarge, u7in-24tb.224xlarge, u7in-32tb.224xlarge
- u7inh-32tb.480xlarge
- x2idn.32xlarge, x2idn.metal
- x2iedn.32xlarge, x2iedn.metal

#### Storage Optimized

- i4g.16xlarge
- i4i.32xlarge, i4i.metal
- i7i.24xlarge, i7i.48xlarge, i7i.metal-48xl
- im4gn.16xlarge

#### Accelerated Computing

- f2.48xlarge
- g6.8xlarge, g6.12xlarge, g6.16xlarge, g6.24xlarge, g6.48xlarge
- g6e.8xlarge, g6e.12xlarge, g6e.16xlarge, g6e.24xlarge, g6e.48xlarge
- gr6.8xlarge
- p5.4xlarge, p5.48xlarge, p5e.48xlarge
- trn1.32xlarge, trn1n.32xlarge

#### High Performance Computing

- hpc6a.48xlarge
- hpc6id.32xlarge
- hpc7a.12xlarge, hpc7a.24xlarge, hpc7a.48xlarge, hpc7a.96xlarge

---

### Nitro v3 (EFA v1) — No RDMA support (unless noted)

#### General Purpose

- m5dn.24xlarge, m5dn.metal
- m5n.24xlarge, m5n.metal
- m5zn.12xlarge, m5zn.metal

#### Compute Optimized

- c5n.9xlarge, c5n.18xlarge, c5n.metal

#### Memory Optimized

- r5dn.24xlarge, r5dn.metal
- r5n.24xlarge, r5n.metal
- x2iezn.12xlarge, x2iezn.metal

#### Storage Optimized

- i3en.12xlarge, i3en.24xlarge, i3en.metal

#### Accelerated Computing

- dl2q.24xlarge
- g4dn.8xlarge, g4dn.12xlarge, g4dn.16xlarge, g4dn.metal
- g5.8xlarge, g5.12xlarge, g5.16xlarge, g5.24xlarge, g5.48xlarge
- inf1.24xlarge
- p3dn.24xlarge
- p4d.24xlarge _(RDMA read supported)_
- p4de.24xlarge _(RDMA read supported)_
- vt1.24xlarge
