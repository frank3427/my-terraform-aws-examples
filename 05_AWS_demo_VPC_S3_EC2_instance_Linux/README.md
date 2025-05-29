# Terraform AWS: Secure S3 Access with VPC Gateway Endpoint and EC2

This Terraform project provisions a secure AWS environment where a Linux EC2 instance interacts with an S3 bucket. The primary access path to S3 is through a VPC Gateway Endpoint, and data access to the S3 bucket from outside this endpoint is explicitly denied by a bucket policy.

## Key Features & Security Aspects

*   **VPC Gateway Endpoint for S3:** Ensures that traffic from the EC2 instance to AWS S3 routes over the AWS private network, avoiding the public internet. This enhances security and can reduce data transfer costs.
*   **S3 Bucket Policy for Endpoint Enforcement:** A stringent S3 bucket policy is applied, denying S3 data operations (like `GetObject`, `PutObject`, `DeleteObject`) unless the request originates from the specified VPC Gateway Endpoint. This effectively blocks direct internet access to the S3 bucket's objects for these critical actions, even if an IAM entity has permissions.
*   **IAM Role and Instance Profile:** The EC2 instance is granted necessary S3 permissions (e.g., `s3:*` or more specific actions) through an IAM instance profile, adhering to the principle of least privilege.
*   **Secure EC2 Access:** The Linux EC2 instance is launched in a public subnet with an Elastic IP, and access is restricted via Security Groups (allowing SSH only from authorized IPs) and Network ACLs.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an associated Internet Gateway (IGW).
*   **Public Subnet:**
    *   A single public subnet within the VPC.
*   **Linux EC2 Instance:**
    *   An Amazon Linux 2 (x86-64) instance launched in the public subnet.
    *   An **Elastic IP (EIP)** is associated for a static public IP address.
    *   Configured with a cloud-init script, potentially for installing AWS CLI, Mountpoint for S3, or other tools.
*   **S3 Bucket:**
    *   A private S3 bucket created with a unique name.
*   **IAM Role and Instance Profile:**
    *   An IAM role with policies granting the EC2 instance permissions to perform S3 operations (e.g., `s3:ListBucket`, `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`).
    *   An IAM instance profile to attach this role to the EC2 instance.
*   **VPC Gateway Endpoint for S3:**
    *   Attached to the VPC and associated with the route table of the public subnet.
    *   This allows resources within the VPC to access S3 services without traversing the public internet.
*   **S3 Bucket Policy:**
    *   Attached to the S3 bucket.
    *   Crucially, this policy includes a **Deny** statement for actions like `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, etc., if the request does not originate from the `aws:SourceVpce` (the VPC Gateway Endpoint for S3).
*   **Networking and Security:**
    *   **Security Group:** For the EC2 instance, allowing inbound SSH (TCP port 22) from `authorized_ips` and necessary outbound traffic.
    *   **Network ACLs (NACLs):** Configured for the public subnet for stateless traffic filtering.

## Architecture: Securing S3 Access

1.  The **EC2 instance**, located in the public subnet, needs to access the **S3 bucket**.
2.  The **IAM Instance Profile** attached to the EC2 instance grants it the necessary S3 permissions at the IAM level.
3.  When the EC2 instance makes an S3 API call (e.g., using AWS CLI), the request is routed through the **VPC Gateway Endpoint for S3** because of the subnet's route table configuration. Traffic stays within the AWS private network.
4.  The S3 service receives the request. Before authorizing based on IAM permissions, it evaluates the **S3 Bucket Policy**.
5.  The bucket policy contains a `Deny` rule for data operations if the `aws:SourceVpce` condition (source VPC endpoint) is not met.
    *   If the request came through the VPC endpoint, this `Deny` condition is not met, and the request proceeds to IAM evaluation.
    *   If a request attempts to access the S3 bucket directly from the internet (i.e., not through the VPC endpoint), the `Deny` condition in the bucket policy is met, and the request is blocked, regardless of IAM permissions.

This combination ensures that even if IAM credentials were to be compromised and used outside the VPC, the bucket policy would prevent unauthorized data access from the internet.

## Key Configuration Variables

*   `aws_region`: The AWS region for resource deployment (e.g., "us-east-1").
*   `az`: The Availability Zone for the public subnet and EC2 instance (e.g., "us-east-1a").
*   `cidr_vpc`: The CIDR block for the new VPC (e.g., "10.50.0.0/16").
*   `cidr_subnet1`: The CIDR block for the public subnet (e.g., "10.50.1.0/24").
*   `authorized_ips`: A list of IP addresses or CIDR blocks authorized for SSH access to the EC2 instance (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `s3_bucket_name`: A globally unique name for the S3 bucket.
*   `inst1_type`: The EC2 instance type (e.g., "t2.micro").
*   `ssh_key_name`: The name of an existing EC2 Key Pair for SSH access.
*   `cloud_init_script_path`: Path to the cloud-init script for EC2 instance setup.

## Usage and Testing Connectivity

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

**After Deployment:**

*   **From the EC2 Instance (via SSH):**
    *   Using the AWS CLI (which should be pre-installed or installed via cloud-init), you should be able to perform S3 operations on the bucket successfully. For example:
        ```bash
        aws s3 ls s3://your-s3-bucket-name/
        echo "Hello from EC2 via VPC Endpoint" > test.txt
        aws s3 cp test.txt s3://your-s3-bucket-name/test.txt
        aws s3 cp s3://your-s3-bucket-name/test.txt downloaded_test.txt
        cat downloaded_test.txt
        ```
    *   If Mountpoint for S3 is configured (e.g., via the cloud-init script), you should be able to mount the bucket and interact with it as a local filesystem.
*   **From Outside the VPC (e.g., your local machine with AWS CLI configured):**
    *   Attempting to perform S3 data operations (like `cp`, `get`, `put`) on the bucket should **fail** due to the S3 bucket policy. For example:
        ```bash
        # Configure your local AWS CLI with credentials that have S3 access
        aws s3 ls s3://your-s3-bucket-name/ # This might succeed as ListBucket is often not restricted by SourceVpce
        echo "Hello from local machine" > local_test.txt
        aws s3 cp local_test.txt s3://your-s3-bucket-name/local_test.txt # This should FAIL
        ```
        You should receive an "Access Denied" error for the `cp` command when executed from outside the VPC, demonstrating the effectiveness of the bucket policy combined with the VPC endpoint.

This setup validates the secure access pattern, ensuring data in the S3 bucket is primarily accessible only from within your VPC through the designated gateway endpoint.
