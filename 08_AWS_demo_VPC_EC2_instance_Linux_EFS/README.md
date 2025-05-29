# Terraform AWS: Linux EC2 Instance with EFS Mount

This Terraform project provisions an AWS environment consisting of a Linux EC2 instance that automatically mounts an AWS Elastic File System (EFS). This setup demonstrates a common pattern for providing scalable, shared file storage to EC2 instances.

## Key Features & Concepts

*   **AWS Elastic File System (EFS):** Provides simple, scalable, elastic file storage for use with AWS Cloud services and on-premises resources. It's designed to be highly durable and available.
*   **EFS Mount Target:** To access an EFS file system from within a VPC, you create one or more mount targets in your VPC subnets. The mount target provides an IP address and DNS name that your EC2 instances use to connect to the EFS file system via the NFSv4 protocol.
*   **Automated Mounting via Cloud-Init:** The EC2 instance uses a cloud-init script. This script is templated with the EFS file system details (like its DNS name) and is responsible for:
    1.  Installing the necessary NFS client utilities (e.g., `amazon-efs-utils` or `nfs-utils`).
    2.  Creating the local mount point directory (e.g., `/mnt/efs`).
    3.  Mounting the EFS file system to this local directory at boot time.
*   **Security Group for NFS Access:** The EC2 instance and the EFS mount target share the VPC's default security group. This security group is configured to allow NFS traffic (TCP/UDP port 2049) from within the VPC itself, enabling the EC2 instance to communicate with the EFS mount target.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an associated Internet Gateway (IGW).
*   **Public Subnet:**
    *   A single public subnet within the VPC.
*   **AWS Elastic File System (EFS):**
    *   Created with default performance mode ("generalPurpose") and throughput mode ("bursting").
    *   Encrypted by default using AWS-managed keys (aws/elasticfilesystem).
*   **EFS Mount Target:**
    *   Created within the public subnet.
    *   Associated with the VPC's default security group. This allows resources in the VPC that are also part of this security group (or have rules allowing traffic to it) to access the EFS.
*   **Linux EC2 Instance:**
    *   An Amazon Linux 2023 (ARM64) instance (or as specified by `var.inst_type`) launched in the public subnet.
    *   An **Elastic IP (EIP)** is associated for a static public IP address.
    *   Uses a **cloud-init script** (from `var.cloud_init_script` template) which receives the EFS file system ID and target mount point (`var.efs_mount_point`) as template variables. The script handles installing the NFS client and mounting the EFS.
*   **Security Group (VPC Default):**
    *   Used by both the EC2 instance and the EFS Mount Target.
    *   **Inbound Rules:**
        *   Allows SSH (TCP port 22) from `authorized_ips` (for EC2 instance access).
        *   Allows all traffic from within the security group itself (source set to the security group ID). This implicitly allows the EC2 instance to communicate with the EFS Mount Target over NFS (port 2049) because both are members of this group.
    *   **Outbound Rules:** Typically allows all outbound traffic by default.
*   **Network ACLs (NACLs):**
    *   Configured for the public subnet to allow inbound SSH, outbound OS update traffic (HTTP/HTTPS), and ephemeral ports for return traffic. Also allows NFS traffic to/from the EFS mount target IP range within the subnet.

## Architecture

The architecture is straightforward:

```
        [ AWS Cloud - Region: var.aws_region, AZ: var.az ]
                         |
        +---------------------------------------------------+
        |                       VPC                       |
        |                (var.cidr_vpc)                   |
        |                                                 |
        |  +-------------------------------------------+  |
        |  |           Public Subnet                   |  |
        |  |         (var.cidr_subnet1)                |  |
        |  |                                           |  |
        |  |  +-------------------+                   |  |
        |  |  |  EC2 Instance     |<----NFS (2049)---->|  | EFS Mount Target
        |  |  |  (EIP)            |   (via Default SG) |  | (IP in Subnet)
        |  |  |  - Cloud-Init     |                   |  |       ^
        |  |  |  - Mounts EFS at  |                   |  |       | (Mounts)
        |  |  |    /mnt/efs       |                   |  |       |
        |  |  +-------------------+                   |  |  +----------+
        |  |          |                               |  |  |   EFS    |
        |  +----------|-------------------------------+  |  | File Sys |
        |             | (SSH from authorized_ips)       |  | (Encrypted)|
        |             ▼                                 |  +----------+
        |        [Internet Gateway]                     |
        +---------------------------------------------------+
                      (Internet)
```

1.  The **EFS file system** is created.
2.  An **EFS Mount Target** is provisioned in the public subnet, making the EFS accessible within that subnet.
3.  The **EC2 Instance** is launched in the same public subnet.
4.  The EC2 instance's **cloud-init script** executes on first boot. It installs `amazon-efs-utils` (which includes an NFS client and helper utilities), creates the directory specified by `var.efs_mount_point`, and then mounts the EFS file system using its DNS name.
5.  The **VPC's default security group**, applied to both the EC2 instance and the EFS mount target, allows the necessary NFS traffic (port 2049) between them because of the rule permitting all traffic from the security group to itself.

## Key Configuration Variables

*   `aws_region`: The AWS region for resource deployment (e.g., "us-east-1").
*   `az`: The Availability Zone for the public subnet, EC2 instance, and EFS mount target (e.g., "us-east-1a").
*   `cidr_vpc`: The CIDR block for the new VPC (e.g., "10.60.0.0/16").
*   `cidr_subnet1`: The CIDR block for the public subnet (e.g., "10.60.1.0/24").
*   `authorized_ips`: A list of IP addresses or CIDR blocks authorized for SSH access to the EC2 instance (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `inst_type`: The EC2 instance type (e.g., "t4g.nano" for ARM64).
*   `ssh_key_name`: The name of an existing EC2 Key Pair for SSH access.
*   `cloud_init_script`: Path to the cloud-init template file (e.g., "cloud_init_al_TEMPLATE.sh"). This template will be rendered with EFS details.
*   `efs_mount_point`: The directory path on the EC2 instance where the EFS will be mounted (e.g., "/mnt/efs").

## Usage

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Verification

After successful deployment:

1.  **SSH into the EC2 Instance:**
    Use its Elastic IP (EIP) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_Instance>
    ```

2.  **Check if EFS is mounted:**
    Run the `df -h` (disk free, human-readable) command. You should see an entry for the EFS mount, similar to:
    ```
    Filesystem             Size  Used Avail Use% Mounted on
    ...
    127.0.0.1:/            8.0E  1.2M  8.0E   1% /mnt/efs  <-- EFS Mount (DNS name might vary)
    # or for EFS file system ID:
    fs-xxxxxxxxxxxxxxxxx.efs.region.amazonaws.com:/  8.0E  1.2M  8.0E   1% /mnt/efs
    ```
    The `Mounted on` column should match your `var.efs_mount_point`.

3.  **Test file operations on the EFS mount point:**
    ```bash
    # Navigate to the EFS mount point
    cd /mnt/efs # Or your var.efs_mount_point

    # Create a test file
    sudo touch test_file_from_ec2.txt
    sudo chmod 666 test_file_from_ec2.txt # Make it writable by ec2-user for easy testing
    echo "Hello from EC2 instance $(hostname)" > test_file_from_ec2.txt

    # Read the file
    cat test_file_from_ec2.txt

    # List files
    ls -l
    ```
    You should be able to create, write to, and read files from this directory. If you launch another EC2 instance (not part of this demo) and mount the same EFS, it would see these files, demonstrating the shared nature of EFS.

Successful execution of these steps confirms that the EFS is correctly mounted and accessible from the EC2 instance.
