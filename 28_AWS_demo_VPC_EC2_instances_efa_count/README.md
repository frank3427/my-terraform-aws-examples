# Terraform AWS: EC2 Cluster with Elastic Fabric Adapter (EFA)

This Terraform project provisions a cluster of Amazon EC2 instances enabled with **Elastic Fabric Adapter (EFA)**. EFA is a network interface for Amazon EC2 instances that enables customers to run applications requiring high levels of inter-node communication, such as High-Performance Computing (HPC) and Machine Learning (ML) workloads, at scale on AWS.

## Purpose

The primary goal of this project is to demonstrate the setup of an EFA-enabled cluster. Key aspects include:
*   Provisioning EC2 instances that are EFA-compatible.
*   Configuring a dual-NIC setup for each instance: one standard ENI for general network access and SSH, and one dedicated EFA ENI for high-bandwidth, low-latency inter-instance communication.
*   Setting up necessary networking (dedicated EFA subnet) and security components (specific EFA security group rules).
*   Using a cluster placement group for optimal network performance between instances.
*   Automating the installation of EFA drivers and supporting software (like Open MPI) via cloud-init.

## Key Components

1.  **VPC Infrastructure:**
    *   A VPC with a **public subnet** and a dedicated **private EFA subnet**.
    *   The public subnet has an Internet Gateway (IGW) for outbound access for tasks like downloading software during cloud-init.
    *   The **private EFA subnet** is specifically for EFA traffic and typically does not have a route to the internet (via IGW or NAT Gateway) to ensure EFA traffic stays on the high-performance fabric.
2.  **EC2 Instances (`aws_instance.demo28_inst`):**
    *   A configurable number of EC2 instances (`var.nb_instances`) are launched.
    *   **EFA-Compatible Instance Type:** The chosen instance type (`var.inst_type`) must support EFA.
    *   **Placement Group (`aws_placement_group.demo28_pg`):**
        *   Instances are launched into a "cluster" placement group. This strategy groups instances closely together within an Availability Zone to achieve the lowest-latency network performance, which is critical for HPC/ML workloads that rely on EFA.
    *   **Dual Network Interfaces:** Each instance is configured with two network interfaces:
        *   **`eth0` (Standard ENI):**
            *   Attached to the **public subnet**.
            *   Assigned a public Elastic IP (EIP) for SSH access and general management traffic.
            *   Uses a standard security group allowing SSH from `authorized_ips`.
        *   **`eth1` (EFA-Enabled ENI):**
            *   Explicitly defined with `interface_type = "efa"`.
            *   Attached to the dedicated **private EFA subnet**. This interface is used for the high-bandwidth, low-latency EFA traffic between instances.
            *   Associated with a specific EFA security group (`aws_security_group.demo28_efa`).
            *   Does not have a public IP address.
3.  **EFA Configuration Specifics:**
    *   **Dedicated EFA Subnet:** The private subnet used for EFA ENIs is configured without a default route to an IGW or NAT Gateway.
    *   **EFA Security Group (`aws_security_group.demo28_efa`):**
        *   This security group is associated with the EFA ENIs (`eth1`).
        *   **Crucial Rule:** It is configured to allow all inbound and outbound traffic **from and to itself** (source/destination set to its own security group ID). This permissive rule within the group is a requirement for EFA to function correctly, allowing unimpeded communication between the EFA devices of the cluster instances.
4.  **Cloud-Init Script (`cloud_init_al.sh` or `cloud_init_ubuntu.sh`):**
    *   Passed to instances via `user_data`.
    *   **Installs EFA Drivers:** Downloads and installs the latest EFA installer and associated drivers.
    *   **Installs Supporting Software:** Typically installs libraries like Open MPI, which are commonly used with EFA for HPC applications.
    *   **Disables ptrace Protection:** Often, `kernel.yama.ptrace_scope` is set to 0. This is a common requirement for MPI applications to allow processes to debug or trace each other.
5.  **Helper Files:**
    *   `efa_instance_types_ARN.txt`: A reference file listing EFA-compatible instance types (may become outdated, always check official AWS documentation).
    *   `list_efa_instance_types_in_region.sh`: A shell script that can be used locally (with AWS CLI configured) to query and list EFA-compatible instance types available in a specific AWS region.
    *   Templates for generating SSH configuration (`sshcfg.template`) and output instructions (`outputs_howto.tpl`) for user convenience.

## Highlights

*   **Purpose of EFA:** Enables tightly coupled HPC/ML applications by providing OS-bypass capabilities for inter-node communication, significantly reducing latency and increasing bandwidth.
*   **Dual-NIC Architecture:** Separation of management traffic (on `eth0` in public subnet) and high-performance EFA traffic (on `eth1` in private EFA subnet).
*   **Cluster Placement Groups:** Essential for ensuring low-latency, high-bandwidth connectivity between EFA-enabled instances.
*   **EFA Security Group Rules:** The specific requirement to allow all traffic from/to the security group itself for EFA interfaces.
*   **Cloud-Init Automation:** Automates the setup of EFA drivers and necessary HPC software on each instance.

## Prerequisites

*   **EFA-Compatible Instance Type:** The selected EC2 instance type (`var.inst_type`) must support EFA. Refer to the AWS documentation or use the provided `list_efa_instance_types_in_region.sh` script to verify.
*   **EFA Drivers & Software:** The cloud-init script handles the installation of EFA drivers and Open MPI. Ensure the script sources are up-to-date or modify as needed.
*   **Sufficient vCPU Quotas:** EFA-enabled instances are often compute-intensive. Ensure your AWS account has sufficient vCPU quotas for the chosen instance type and number of instances in the target region.

## Key Configuration Variables

*   `aws_region`: AWS region for deployment.
*   `az`: Availability Zone for all resources.
*   `cidr_vpc`, `cidr_subnet1_public`, `cidr_subnet2_efa`: CIDR blocks.
*   `authorized_ips`: IPs/CIDRs for SSH access.
*   `nb_instances`: Number of EFA-enabled EC2 instances to launch.
*   `inst_type`: The EC2 instance type (must be EFA-compatible, e.g., "c5n.large", "p4d.24xlarge").
*   `al_ssh_key_name` / `ubuntu_ssh_key_name`: Name of an existing EC2 Key Pair.
*   `user_data_script`: Path to the cloud-init script (`cloud_init_al.sh` or `cloud_init_ubuntu.sh`).

## Usage

1.  **Select Instance Type and AMI:** Ensure `var.inst_type` is EFA-compatible and `var.ami_id` matches your chosen OS and region.
2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
3.  **Plan Changes:**
    Review the resources that Terraform will create.
    ```bash
    terraform plan
    ```
4.  **Apply Changes:**
    Provision the AWS resources.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. An `sshcfg` file will be generated for easy SSH access.

## Testing EFA Connectivity

After successful deployment and the cloud-init script has completed on all instances:

1.  **SSH into one of the EC2 Instances:**
    Use the generated `sshcfg` file or the instance's EIP.
    ```bash
    # Using generated sshcfg
    ssh demo28-1
    # Or directly
    # ssh -i /path/to/your/ssh-key.pem <user>@<EIP_Instance1>
    ```

2.  **Verify EFA Interface:**
    On the instance, check for the EFA network interface (usually `eth1` or a similar name given to the second interface).
    ```bash
    ip addr # Look for the EFA interface and its IP in the private EFA subnet
    fi_info -p efa # Should show EFA provider information
    ```

3.  **Run MPI Ping-Pong Tests (if Open MPI is installed):**
    This is a common way to test basic EFA connectivity and performance between two nodes.
    *   You'll need a hostfile listing the private IPs of the EFA interfaces of your cluster nodes.
    *   Example using `osu_latency` (part of OSU Micro-Benchmarks, often installed with Open MPI or compiled separately):
        ```bash
        # On node 1 (e.g., demo28-1)
        # Ensure your hostfile (e.g., myhosts) contains the private EFA IP of demo28-1 and demo28-2
        # e.g.,
        # 10.x.x.x # EFA IP of demo28-1
        # 10.x.x.y # EFA IP of demo28-2

        mpirun -np 2 --hostfile myhosts /path/to/osu_latency
        # Or for bandwidth:
        # mpirun -np 2 --hostfile myhosts /path/to/osu_bibw
        ```
    *   Low latency values (a few microseconds for `osu_latency`) indicate EFA is working correctly.

4.  **Refer to AWS EFA Documentation:**
    AWS provides specific tests and diagnostic tools for EFA. Consult the official AWS documentation for the most up-to-date methods for verifying EFA functionality, such as using `efa-config-check.sh` or running libfabric tests.

This setup provides a high-performance computing foundation. Application-level performance will depend on how well the application is optimized to use EFA and MPI.
