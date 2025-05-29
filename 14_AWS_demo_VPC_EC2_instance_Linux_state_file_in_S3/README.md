# Terraform AWS: Storing Terraform State File in S3

This Terraform project primarily demonstrates how to configure Terraform to store its state file remotely in an **AWS S3 bucket**. The actual AWS resources provisioned by this project (a simple VPC and a Linux EC2 instance) are for illustrative purposes to show the backend configuration in action.

## Purpose

The main goal of this project is to showcase and explain the setup of a **Terraform S3 backend**. Remote state management is a best practice in Terraform for several reasons:

*   **Collaboration:** Allows multiple team members to work on the same infrastructure by sharing a centralized state.
*   **Consistency:** Ensures that everyone is working with the same version of the state, preventing conflicts.
*   **Security:**
    *   State files can contain sensitive information. Storing them remotely allows for better access control and security measures (e.g., S3 bucket policies, encryption).
    *   S3 supports versioning, which can help recover from accidental state modifications.
    *   S3 supports state locking (typically via DynamoDB, though not explicitly configured in this basic backend block example) to prevent concurrent operations from corrupting the state.
*   **Durability:** Protects the state file from being lost if a local machine fails.

The AWS resources (VPC, EC2 instance) are secondary and serve as a working example that requires a state file.

## S3 Backend Configuration Details

The configuration for the S3 backend is defined within the `terraform { ... }` block, typically in a provider configuration file (e.g., `02_provider.tf` in this project).

```terraform
terraform {
  backend "s3" {
    region = "eu-west-3"  # Example: AWS Region of the S3 bucket
    bucket = "cpa7777"     # Example: Name of the S3 bucket
    key    = "terraform/demo14.tfstate" # Example: Path/name of the state file in the bucket
    # encrypt = true # Optional: server-side encryption
    # dynamodb_table = "terraform-locks" # Optional: for state locking
  }
}
```

Key parameters in this block:

*   `region`: Specifies the AWS region where the S3 bucket is located. **In this example, it is hardcoded to "eu-west-3"**.
*   `bucket`: The globally unique name of the S3 bucket that will store the Terraform state file. **In this example, it is hardcoded to "cpa7777"**.
*   `key`: The path and filename for the state file within the S3 bucket. This allows for organizing state files for different projects or environments within the same bucket. **In this example, it is hardcoded to "terraform/demo14.tfstate"**.

**Important Considerations:**

*   **Pre-existing Bucket:** The S3 bucket specified in the `bucket` parameter **must exist before you run `terraform init`**. Terraform will not create this bucket for you.
*   **Hardcoded Values:** In this demonstration project, the `region`, `bucket`, and `key` are hardcoded directly into the `backend` block. In real-world scenarios, especially for reusable modules or team environments, these values might be:
    *   Partially configured and completed during `terraform init` using `-backend-config` options.
    *   Managed via CI/CD variables.
    *   Stored in a separate configuration file that is not committed to the repository if it contains sensitive information (though backend configuration itself is generally not sensitive, the chosen bucket name might be).
*   **Permissions:** The AWS credentials used by Terraform must have the necessary IAM permissions to read and write objects in the specified S3 bucket, as well as to create and manage DynamoDB table entries if state locking is enabled.

## Provider Configuration Note

The AWS provider used for provisioning the example resources (`provider "aws" { ... }`) is configured separately from the S3 backend. This means:

*   The AWS region for the S3 backend (where the state file is stored) can be different from the AWS region where the actual infrastructure resources are deployed (`var.aws_region`).
*   For instance, your S3 bucket for state files could be in `us-east-1`, while you deploy resources to `eu-west-1`. This project demonstrates this by hardcoding the backend region and using a variable for the resource provisioning region.

## AWS Resources Provisioned (Example Infrastructure)

For the purpose of demonstrating the S3 backend, this project provisions a simple set of AWS resources:

*   **VPC:** A standard Virtual Private Cloud.
*   **Public Subnet:** A subnet within the VPC with a route to the Internet Gateway.
*   **Internet Gateway (IGW):** Allows internet access for the VPC.
*   **Linux EC2 Instance:** An Amazon Linux 2 instance launched in the public subnet.
*   **Elastic IP (EIP):** Associated with the EC2 instance for a static public IP.
*   **Security Group:** Basic rules allowing SSH access to the EC2 instance.
*   **Network ACLs:** Default NACLs, typically allowing all traffic.

## Key Configuration Variables (for Example Infrastructure)

These variables are used for configuring the illustrative AWS resources, not the S3 backend itself (which is hardcoded in this example).

*   `aws_region`: The AWS region where the example VPC and EC2 instance will be deployed (e.g., "us-east-1").
*   `az`: The Availability Zone for the public subnet and EC2 instance (e.g., "us-east-1a").
*   `cidr_vpc`: CIDR block for the example VPC (e.g., "10.110.0.0/16").
*   `cidr_subnet1`: CIDR block for the public subnet in the example VPC (e.g., "10.110.1.0/24").
*   `authorized_ips`: List of IPs/CIDRs for SSH access to the EC2 instance (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `inst1_type`: EC2 instance type (e.g., "t2.micro").
*   `al2_ssh_key_name`: Name of an existing EC2 Key Pair in the `aws_region` for SSH access.

## Usage

1.  **Prerequisite:** Ensure the S3 bucket (e.g., "cpa7777") and the specified path prefix (e.g., "terraform/") exist in the correct AWS region (e.g., "eu-west-3") and that your AWS credentials have access to it.

2.  **Initialize Terraform:**
    This is a critical step. When you run `terraform init`, Terraform reads the `backend "s3"` configuration.
    ```bash
    terraform init
    ```
    Terraform will detect the backend block and ask if you want to migrate your state to S3 (if you previously had local state) or initialize the S3 backend.

3.  **Plan Changes:**
    ```bash
    terraform plan
    ```
    Terraform will now read state (if any) from S3 and compare it against your configuration.

4.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. After applying, Terraform will write the updated state file to the configured S3 bucket and key.

If you inspect your S3 bucket (e.g., `s3://cpa7777/terraform/demo14.tfstate`), you will find the Terraform state file stored there. Subsequent `plan` and `apply` operations will use this remote state.
