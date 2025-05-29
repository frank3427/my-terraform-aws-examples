# Terraform AWS: AWS ParallelCluster with `awscc` Provider (Single Subnet)

This Terraform project demonstrates how to provision an **AWS ParallelCluster** environment using the **AWS Cloud Control (awscc) provider**. This setup is designed for High-Performance Computing (HPC) workloads and includes shared storage solutions (Amazon EFS and Amazon FSx for Lustre).

For simplicity, this particular example utilizes a **single public subnet** for all cluster resources, including the head node, compute nodes, and storage access points.

## Purpose

The primary goals of this project are to:
1.  Illustrate the deployment of an AWS ParallelCluster environment using the newer `awscc` provider resources (`awscc_pcs_cluster`, `awscc_pcs_compute_node_group`, `awscc_pcs_queue`).
2.  Showcase the integration of shared file systems (EFS for general-purpose shared storage and FSx for Lustre for high-performance, parallel I/O) commonly used in HPC.
3.  Provide a basic Slurm workload manager configuration.
4.  Offer a simplified network architecture (single public subnet) for easier understanding and quick deployment, while acknowledging this differs from typical production setups.

## Key Components

1.  **VPC & Network Infrastructure:**
    *   A single **VPC** is created.
    *   One **public subnet** is configured within this VPC. All AWS ParallelCluster resources (head node, compute nodes) and storage mount targets/access points are deployed within this single public subnet.
    *   An **Internet Gateway (IGW)** is attached to the VPC to provide internet access to resources in the public subnet.
    *   A single **Security Group** is primarily used for the cluster. It allows:
        *   Inbound SSH (TCP port 22) from `authorized_ips` (for access to the head node).
        *   All internal traffic within the security group itself (self-referencing rule), enabling communication between the head node and compute nodes for Slurm and internode MPI traffic.
    *   **Network ACLs (NACLs):** Configured to be permissive, allowing all traffic to and from the subnet.
2.  **AWS ParallelCluster (`awscc_pcs_cluster.pcs_cluster`):**
    *   This is the central resource defining the ParallelCluster environment, deployed using the `awscc_pcs_cluster` resource type.
    *   **Scheduler:** Configured to use **SLURM** as the job scheduler, with a specified version (e.g., `var.pcs_slurm_version`).
    *   **Cluster Size/Configuration:** A general cluster size parameter (e.g., "SMALL") might be used, which influences default settings. Specific networking details point to the single public subnet.
3.  **Compute Node Group (`awscc_pcs_compute_node_group.cpt_nodes_a`):**
    *   Defines the characteristics of the compute nodes that will execute jobs.
    *   **Launch Template (`aws_launch_template.cpt_nodes_a`):**
        *   A custom launch template is used for the compute nodes.
        *   Specifies a ParallelCluster compatible Amazon Machine Image (AMI) suitable for Slurm (e.g., an official AWS ParallelCluster AMI for Amazon Linux 2 or Ubuntu).
        *   Includes **User Data (cloud-init script):** This script is crucial for:
            *   Mounting the shared Amazon EFS file system.
            *   Mounting the shared Amazon FSx for Lustre file system.
            *   Other necessary compute node setup.
    *   **Instance Configuration:**
        *   Configurable instance type (`var.cpt_nodes_inst_type`) and desired count (`var.cpt_nodes_count`) for the compute nodes.
    *   **IAM Instance Profile:** Associated with an IAM role that grants compute nodes necessary permissions (e.g., to access S3, CloudWatch Logs, and potentially EFS/FSx if IAM authorization is used, though typically network access is via security groups).
4.  **SLURM Queue (`awscc_pcs_queue.queue_a`):**
    *   A SLURM queue (partition) is created.
    *   This queue is associated with the `awscc_pcs_compute_node_group.cpt_nodes_a`, meaning jobs submitted to this queue will run on instances from this node group.
5.  **Shared Storage:**
    *   **Amazon EFS (`aws_efs_file_system.efs`):**
        *   An Elastic File System is provisioned to provide general-purpose, scalable, shared file storage accessible by both the head node and compute nodes (e.g., for home directories, shared applications, scripts).
        *   An **EFS Mount Target (`aws_efs_mount_target`)** is created in the public subnet to make the EFS accessible to instances within that subnet.
    *   **Amazon FSx for Lustre (`aws_fsx_lustre_file_system.fsx_lustre`):**
        *   An FSx for Lustre file system is provisioned. This is a high-performance file system optimized for fast parallel I/O, suitable for scratch space or large datasets used in HPC computations.
        *   It is also made accessible to instances in the public subnet (network interface for FSx for Lustre is created in this subnet).
6.  **Slurm Scripts (`slurm_scripts/` directory):**
    *   The project includes a `slurm_scripts/` directory containing example Slurm job submission scripts (e.g., `test1.sh`). These scripts can be used to test the cluster functionality by submitting simple jobs.

## Network Architecture Note

This project uses a **single public subnet** for all cluster components (head node, compute nodes, EFS mount target, FSx for Lustre network interface).

*   **Simplicity:** This design simplifies the network configuration and is suitable for quick demonstrations or development environments.
*   **Production Considerations:** For production HPC environments, a more typical architecture involves:
    *   Placing the **head node** in a public subnet (for direct SSH access).
    *   Placing **compute nodes** in private subnets with a NAT Gateway for outbound internet access (for OS updates, package downloads) or no internet access if not required.
    *   Using VPC endpoints for accessing AWS services like S3, ECR, and CloudWatch Logs privately.
    This enhances security by isolating compute nodes from direct internet exposure. This example deviates from that for simplicity.

## Shared Storage in HPC

*   **Amazon EFS:** Provides a simple, scalable, and elastic NFS file system. It's well-suited for home directories, shared software installations, and general-purpose file sharing among cluster nodes.
*   **Amazon FSx for Lustre:** Offers a high-performance, POSIX-compliant file system optimized for workloads that require fast, parallel access to large datasets (e.g., scratch space for computations, input/output datasets for simulations).

Both are mounted on the head node and compute nodes (via the launch template's user data) to provide a consistent file environment.

## Highlights

*   **`awscc` Provider for ParallelCluster:** Demonstrates the use of the AWS Cloud Control provider for deploying and managing AWS ParallelCluster resources.
*   **Simplified Single-Subnet Architecture:** Easy to understand and deploy for introductory purposes.
*   **EFS and FSx for Lustre Integration:** Showcases common shared storage solutions used in HPC clusters for different purposes.
*   **Slurm Scheduler:** Uses Slurm, a popular open-source workload manager for HPC clusters.

## Key Configuration Variables

*   **General AWS & VPC:** `aws_region`, `az1` (single AZ used for the subnet), `cidr_vpc`, `cidr_subnet_public`.
*   **ParallelCluster & Slurm:**
    *   `pcs_cluster_name`.
    *   `pcs_slurm_version` (e.g., "3.7.0").
*   **Compute Nodes:**
    *   `cpt_nodes_count`: Desired number of compute nodes.
    *   `cpt_nodes_inst_type`: EC2 instance type for compute nodes (must be compatible with ParallelCluster and chosen AMI).
*   **Shared Storage:**
    *   EFS related: `efs_mount_point` (e.g., "/shared_efs").
    *   FSx for Lustre related: `fsx_lustre_mount_point` (e.g., "/fsx"), `fsx_lustre_storage_capacity_gb`.
*   **EC2 Access:** `al2_ssh_key_name`, `authorized_ips`.

## Usage

1.  **Prerequisites:**
    *   Ensure the chosen EC2 instance type (`var.cpt_nodes_inst_type`) is available in your selected region and supports the ParallelCluster version and AMI.
    *   Ensure your AWS account has sufficient service quotas for VPCs, EC2 instances (especially if using specialized HPC types), EFS, FSx for Lustre, and ParallelCluster resources.
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
    Provision the AWS ParallelCluster environment. This process can take a significant amount of time (20-40 minutes or more) as it involves creating multiple complex resources.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. Terraform will output the public IP address of the head node.

## Submitting Jobs to Slurm

After successful deployment and the cluster status is "CREATE_COMPLETE":

1.  **SSH into the Head Node:**
    Use the public IP address of the head node (from Terraform output) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<Head_Node_Public_IP>
    ```
    (The default user might vary based on the ParallelCluster AMI, e.g., `ec2-user` for Amazon Linux based, `ubuntu` for Ubuntu based).

2.  **Check Cluster Status (Optional):**
    Once on the head node, you can use ParallelCluster CLI commands (if installed) or Slurm commands.
    ```bash
    sinfo  # Shows information about Slurm nodes and partitions (queues)
    squeue # Shows jobs currently in the queue
    ```

3.  **Navigate to Shared Storage / Scripts:**
    The `slurm_scripts/` directory from your local project is not automatically copied. You'll need to transfer your job scripts to the head node (e.g., using `scp`) or create them there, preferably on one of the shared file systems (EFS or FSx).
    For example, if EFS is mounted at `/shared_efs`:
    ```bash
    cd /shared_efs
    # Create or scp your slurm_scripts here
    # Example: scp -i /path/to/your/ssh-key.pem local_path/slurm_scripts/* ec2-user@<Head_Node_Public_IP>:/shared_efs/slurm_scripts/
    ```

4.  **Submit an Example Job:**
    Assuming you have a simple Slurm script like `test1.sh` in a directory on the shared storage (e.g., `/shared_efs/slurm_scripts/test1.sh`):
    ```slurm
    #!/bin/bash
    #SBATCH --job-name=mySimpleTest
    #SBATCH --output=mySimpleTest-%j.out
    #SBATCH --nodes=1
    #SBATCH --ntasks-per-node=1
    #SBATCH --time=00:05:00

    echo "Hello from node $(hostname)"
    sleep 60
    ```
    Submit the job using `sbatch`:
    ```bash
    cd /shared_efs/slurm_scripts/ # Or wherever your script is
    sbatch test1.sh
    ```

5.  **Monitor Job Status:**
    *   `squeue`: Shows the status of jobs in the queue.
    *   `sacct`: Shows accounting information for completed jobs.
    *   Check the output file (e.g., `mySimpleTest-<job_id>.out`) in the submission directory.

6.  **Cancel a Job (if needed):**
    ```bash
    scancel <job_id>
    ```

This provides a basic workflow for interacting with the Slurm scheduler on your AWS ParallelCluster. Refer to AWS ParallelCluster and Slurm documentation for more advanced usage. Remember the network architecture of this example is simplified for demonstration.
