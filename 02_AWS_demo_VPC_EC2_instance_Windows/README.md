# Terraform AWS VPC and Windows EC2 Instance

This Terraform project provisions a complete environment for a Windows Server EC2 instance within a new Virtual Private Cloud (VPC) on AWS. It includes networking setup, security configurations for RDP access, and management of the instance's administrator password.

## AWS Resources Provisioned

This project will create the following AWS resources:

*   **VPC:** A new VPC is created to provide an isolated network environment.
    *   **Internet Gateway:** Enables communication between instances in the VPC and the internet.
    *   **Public Subnet:** A subnet where instances can have public IP addresses and direct internet access.
    *   **Default Route Table:** Configured to route internet-bound traffic through the Internet Gateway.
    *   **Network ACLs (NACLs):** Configured to allow RDP traffic (TCP port 3389) from specified IP addresses and other necessary traffic.
*   **EC2 Instance:**
    *   A **Windows Server EC2 instance** is launched using a Windows Server 2022 AMI.
    *   An **Elastic IP (EIP)** is associated with the EC2 instance to provide a static public IP address.
*   **Security Group:** A security group is configured to allow inbound RDP access (TCP port 3389) from specified authorized IP addresses.
*   **AWS Key Pair:**
    *   A new AWS Key Pair is created. The public key material is derived from a locally generated TLS private key (`tls_private_key`).
    *   This key pair is associated with the EC2 instance and is crucial for retrieving the initial Administrator password.
*   **Administrator Password Management:**
    *   The initial randomly generated Administrator password for the Windows instance is encrypted by AWS using the associated key pair.
    *   Terraform retrieves this encrypted password and decrypts it using the local private key.
    *   The decrypted **Administrator password is saved to a local file**.
*   **RDP Connection File:** An `.rdp` file is generated locally, pre-configured with the Elastic IP of the EC2 instance, making it easy to connect.
*   **EBS Volume:** An additional **EBS volume (40GB, gp2, encrypted)** is created and attached to the Windows instance.

## Key Configuration Variables

Users may need to configure the following variables in their Terraform configuration (e.g., in a `terraform.tfvars` file or via command-line arguments):

*   `aws_region`: The AWS region where the resources will be deployed (e.g., "us-east-1").
*   `cidr_vpc`: The CIDR block for the new VPC (e.g., "10.0.0.0/16").
*   `cidr_subnet1`: The CIDR block for the public subnet (e.g., "10.0.1.0/24").
*   `authorized_ips`: A list of IP addresses or CIDR blocks authorized for RDP access (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `az`: The Availability Zone for the subnet and EC2 instance (e.g., "us-east-1a").
*   `inst1_type`: The EC2 instance type (e.g., "t2.medium").
*   `public_rsakey_path`: The path where the generated RSA public key file will be saved (e.g., "windows-key.pub").
*   `private_rsakey_path`: The path where the generated RSA private key file will be saved (e.g., "windows-key.pem"). This is the `tls_private_key` output.
*   `decrypted_pwd_file`: The path to the local file where the decrypted Windows Administrator password will be stored (e.g., "windows_admin_password.txt").

## Usage

1.  **Initialize Terraform:**
    Navigate to the directory containing the Terraform files and run:
    ```bash
    terraform init
    ```

2.  **Plan Changes (Optional but Recommended):**
    Review the resources that Terraform will create:
    ```bash
    terraform plan
    ```

3.  **Apply Changes:**
    Provision the AWS resources:
    ```bash
    terraform apply
    ```
    You will be prompted to confirm the action. Type `yes` to proceed.

## Key Files Created by Terraform

After a successful `terraform apply`, the following key files will be created locally (based on the configured paths):

*   **RSA Public Key:** (e.g., `windows-key.pub`) - The public part of the key pair associated with the EC2 instance.
*   **RSA Private Key:** (e.g., `windows-key.pem`) - The private part of the key pair, used to decrypt the Windows Administrator password. **Keep this file secure and private.**
*   **Decrypted Administrator Password File:** (e.g., `windows_admin_password.txt`) - Contains the initial Administrator password for the Windows EC2 instance.
*   **RDP Connection File:** (e.g., `instance.rdp`) - A pre-configured Remote Desktop Protocol file to connect to the Windows instance.

After provisioning, you can use the RDP file and the decrypted password to connect to your Windows Server instance. Remember to secure the private key and the password file.
