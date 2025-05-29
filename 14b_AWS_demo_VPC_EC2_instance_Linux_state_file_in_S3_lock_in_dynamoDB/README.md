# Terraform AWS: S3 Remote State with DynamoDB Locking

This Terraform project demonstrates an enhanced setup for remote state management using an **AWS S3 bucket for state file storage** and an **AWS DynamoDB table for state locking**. This configuration builds upon the basic S3 backend by adding a crucial layer of safety for collaborative environments.

The actual AWS resources provisioned by this project (a simple VPC and a Linux EC2 instance) are for illustrative purposes to showcase the backend and locking mechanism in action.

## Purpose

The primary goal is to illustrate a robust remote state management strategy. While storing state in S3 (as shown in project `14_`) provides shared access and durability, **state locking** adds a critical feature:

*   **Preventing Concurrent State Modifications:** When one user runs `terraform apply`, a lock is placed in the DynamoDB table. If another user attempts to run `apply` on the same state concurrently, Terraform will detect the lock and prevent the operation, thus avoiding potential state corruption or conflicts.
*   **Ensuring Consistency:** Guarantees that only one process is modifying the state at any given time, leading to a more stable and predictable infrastructure management experience.
*   **Collaboration Safety:** Essential for teams where multiple members might be working on the same Terraform configurations.

The DynamoDB table provides the mechanism for Terraform to acquire and release these locks.

## S3 Backend & DynamoDB Lock Configuration

The configuration for the S3 backend with DynamoDB locking is defined within the `terraform { ... }` block, typically in a provider configuration file (e.g., `02_provider.tf` in this project).

```terraform
terraform {
  backend "s3" {
    region = "eu-west-3"  # Example: AWS Region of the S3 bucket & DynamoDB table
    bucket = "cpa7777"     # Example: Name of the S3 bucket
    key    = "terraform/demo14b.tfstate" # Example: Path/name of the state file
    
    # DynamoDB Table for State Locking
    dynamodb_table = "TerraformLock" 
    # encrypt        = true # Optional: server-side encryption for S3 state file
  }
}
```

Key parameters in this block:

*   `region`: Specifies the AWS region where the S3 bucket **and** the DynamoDB table are located. Both must be in the same region. **In this example, it is hardcoded to "eu-west-3"**.
*   `bucket`: The globally unique name of the S3 bucket for storing the state file. **In this example, it is hardcoded to "cpa7777"**.
*   `key`: The path and filename for the state file within the S3 bucket. **In this example, it is hardcoded to "terraform/demo14b.tfstate"**.
*   `dynamodb_table`: This is the crucial parameter that enables state locking. It specifies the name of the DynamoDB table that Terraform will use to manage locks. **In this example, it is hardcoded to "TerraformLock"**.

**Important Considerations:**

*   **Pre-existing Resources:** Both the S3 bucket and the DynamoDB table **must exist before you run `terraform init`**. Terraform will not create these backend components for you.
*   **Hardcoded Values:** In this project, `region`, `bucket`, `key`, and `dynamodb_table` are hardcoded. For production or team environments, consider more dynamic configuration methods (e.g., using `-backend-config` during `init`).
*   **Permissions:** The AWS credentials used by Terraform need IAM permissions for:
    *   S3: Read/write objects in the specified bucket.
    *   DynamoDB: Read/write items in the `TerraformLock` table (specifically actions like `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem`).

## Prerequisites (Creating DynamoDB Table)

For state locking to function, the specified DynamoDB table must exist. This project includes a helper script `00_create_dynamodb_table.sh` to facilitate its creation.

**`00_create_dynamodb_table.sh` Script:**

*   **Purpose:** This shell script uses the AWS CLI to create the DynamoDB table named `TerraformLock`.
*   **Table Schema:**
    *   Primary Key: `LockID` (AttributeType: `S`, for String). This is the attribute Terraform uses to store lock information.
*   **Provisioned Throughput:** The script defines basic provisioned throughput settings (e.g., ReadCapacityUnits: 5, WriteCapacityUnits: 5). For most Terraform use cases, on-demand capacity might also be suitable.
*   **Region:** The script should be run targeting the same AWS region specified in the `backend "s3"` configuration (e.g., "eu-west-3").

**To use the script:**
1.  Ensure your AWS CLI is installed and configured with credentials having permissions to create DynamoDB tables.
2.  Modify the script if needed (e.g., to change the region or table name, though it should match the backend config).
3.  Execute the script:
    ```bash
    sh 00_create_dynamodb_table.sh
    ```
Alternatively, you can create the DynamoDB table through the AWS Management Console or other infrastructure-as-code tools, ensuring it has a primary key named `LockID` of type String.

## AWS Resources Provisioned (Example Infrastructure)

For demonstration, this project provisions a simple AWS infrastructure:

*   **VPC:** A standard Virtual Private Cloud.
*   **Public Subnet:** A subnet within the VPC.
*   **Internet Gateway (IGW):** For internet access.
*   **Linux EC2 Instance:** An Amazon Linux 2 instance.
*   **Elastic IP (EIP):** For the EC2 instance.
*   **Security Group & Network ACLs:** Basic configurations.

These resources are illustrative and their state will be managed using the configured S3 backend with DynamoDB locking.

## Key Configuration Variables (for Example Infrastructure)

These variables configure the example AWS resources:

*   `aws_region`: The AWS region for deploying the example VPC and EC2 (e.g., "us-east-1"). This can be different from the S3 backend region.
*   `az`: Availability Zone for the EC2 instance and subnet.
*   `cidr_vpc`: CIDR for the example VPC.
*   `cidr_subnet1`: CIDR for the public subnet.
*   `authorized_ips`: IPs/CIDRs for SSH access to EC2.
*   `inst1_type`: EC2 instance type.
*   `al2_ssh_key_name`: Name of an existing EC2 Key Pair.

## Usage

1.  **Prerequisites:**
    *   Ensure the S3 bucket (e.g., "cpa7777") exists in the backend region (e.g., "eu-west-3").
    *   Create the DynamoDB table (e.g., "TerraformLock") in the same backend region using the `00_create_dynamodb_table.sh` script or other means.

2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
    Terraform will initialize the S3 backend and verify connectivity to the DynamoDB table for locking.

3.  **Plan Changes:**
    ```bash
    terraform plan
    ```

4.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    When `apply` starts, Terraform will attempt to acquire a lock using the DynamoDB table. If successful, the state file in S3 will be updated upon completion. If another user tries to `apply` concurrently, they will receive a message indicating that the state is locked.

This setup significantly improves the safety and reliability of managing Terraform state, especially in team environments. Remember that the S3 bucket and DynamoDB table names/regions are hardcoded in this example for simplicity.
