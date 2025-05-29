# Terraform AWS: Robust S3 Backend with DynamoDB Locking (Two-Step Setup)

This Terraform project demonstrates a best-practice setup for managing Terraform state remotely and securely. It uses an **AWS S3 bucket for state file storage** (with versioning and server-side encryption enabled) and an **AWS DynamoDB table for state locking**.

A unique aspect of this project is its **two-step process**:
1.  A prerequisite Terraform configuration in the `00_PREREQ/` directory is used to provision the S3 bucket and DynamoDB table themselves.
2.  The main Terraform configuration then uses these pre-created resources for its backend.

## Purpose

The primary goal is to illustrate a robust and secure remote state management strategy, crucial for team collaboration and production environments:

*   **S3 for State Storage:**
    *   **Durability & Availability:** S3 provides a highly durable and available location for your Terraform state files.
    *   **Versioning:** The S3 bucket is configured with versioning enabled, allowing you to roll back to previous state file versions if necessary.
    *   **Encryption:** Server-side encryption (AES256) is enabled on the S3 bucket, ensuring your state file (which can contain sensitive information) is encrypted at rest.
*   **DynamoDB for State Locking:**
    *   **Prevents Concurrent Modifications:** When a Terraform operation that modifies state (like `apply` or `destroy`) is initiated, Terraform places a lock in the DynamoDB table.
    *   **Ensures Consistency:** If another user or process attempts to modify the same state simultaneously, they will be blocked until the lock is released, preventing state corruption and race conditions.
    *   **Collaboration Safety:** Essential for teams, as it ensures only one person is applying changes at a time.
*   **Infrastructure as Code for Backend:** Demonstrates managing your backend infrastructure (S3 bucket, DynamoDB table) using Terraform itself.

## Overview of the Two-Step Process

This project requires a sequential deployment:

1.  **Step 1: Provision Backend Resources (`00_PREREQ/` directory):**
    *   First, you navigate to the `00_PREREQ/` subdirectory and run Terraform commands there.
    *   This initial configuration creates the S3 bucket (for state storage) and the DynamoDB table (for state locking).
2.  **Step 2: Configure and Deploy the Main Project (root `31_AWS_demo_s3_backend/` directory):**
    *   After the backend resources are successfully provisioned, you navigate back to the main project directory.
    *   The Terraform configuration here is set up to use the S3 bucket and DynamoDB table created in Step 1 as its remote backend.
    *   This main project then provisions example AWS resources (a VPC and an EC2 instance) to demonstrate the backend in action.

## Step 1: Provisioning Backend Resources (`00_PREREQ/` directory)

This subdirectory contains a self-contained Terraform configuration responsible for creating the S3 bucket and DynamoDB table that will serve as the remote backend.

*   **S3 Bucket (`aws_s3_bucket.terraform_state`):**
    *   **Purpose:** Stores the Terraform state file (`.tfstate`).
    *   **Versioning:** Created with `versioning_configuration { status = "Enabled" }` to keep a history of state file changes.
    *   **Server-Side Encryption:** Configured with `server_side_encryption_configuration { rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } } }` to ensure the state file is encrypted at rest in S3.
    *   **Naming:** The bucket name is determined by the `var.s3_bucket_backend` variable within this prerequisite configuration.
*   **DynamoDB Table (`aws_dynamodb_table.terraform_locks`):**
    *   **Purpose:** Used by Terraform for state locking to prevent concurrent operations.
    *   **Primary Key:** Must have a primary key (hash key) named `LockID` of type String (`S`). This specific schema is required by Terraform for its DynamoDB locking mechanism.
    *   **Billing Mode/Capacity:** Typically configured with `PROVISIONED` throughput (as in this example) or `PAY_PER_REQUEST`.
    *   **Naming:** The table name is determined by the `var.dynamodb_table_backend` variable within this prerequisite configuration.

**It is crucial to run `terraform apply` in the `00_PREREQ/` directory and ensure these resources are created successfully before proceeding to the main project configuration.**

## Step 2: Configuring the Main Project (`31_AWS_demo_s3_backend/`)

This is the root directory of the project and contains the main Terraform configuration that will deploy example AWS infrastructure (a VPC and an EC2 instance). Its state will be managed by the resources created in Step 1.

*   **S3 Backend Configuration (`02_provider.tf`):**
    The `terraform { backend "s3" { ... } }` block in this file tells Terraform to use the S3 remote backend:
    ```terraform
    terraform {
      backend "s3" {
        bucket         = "demo31-tf-state-cpauliat" # MUST match S3 bucket from 00_PREREQ/
        key            = "terraform.tfstate"
        region         = "eu-west-1"              # MUST match region of S3/DynamoDB from 00_PREREQ/
        dynamodb_table = "demo31_tf_state"        # MUST match DynamoDB table from 00_PREREQ/
        encrypt        = true                     # Ensures state is encrypted in transit to S3
      }
    }
    ```
    *   `bucket`: The name of the S3 bucket created in Step 1. **This value is hardcoded in this example and must exactly match the name of the S3 bucket you provisioned.**
    *   `key`: The path/name for the state file within the S3 bucket (e.g., `terraform.tfstate`). This is also hardcoded.
    *   `region`: The AWS region where the S3 bucket and DynamoDB table exist. This is hardcoded and must match the region used in Step 1.
    *   `dynamodb_table`: The name of the DynamoDB table created in Step 1 for state locking. **This value is hardcoded and must exactly match the name of the DynamoDB table you provisioned.**
    *   `encrypt = true`: This option ensures that the state data is encrypted before being written to the S3 bucket, providing an additional layer of security for data in transit to S3. The S3 bucket itself is already configured for server-side encryption at rest.

*   **Example AWS Resources Provisioned:**
    For demonstration, this main project provisions:
    *   A standard Virtual Private Cloud (VPC).
    *   An EC2 instance within the VPC.
    The state of these resources will be stored in the configured S3 bucket and locked using the DynamoDB table.

## Key Configuration Variables

*   **For `00_PREREQ/` (Backend Infrastructure):**
    *   `aws_region_backend`: The AWS region where the S3 bucket and DynamoDB table will be created (e.g., "eu-west-1").
    *   `s3_bucket_backend`: The desired globally unique name for the S3 state bucket.
    *   `dynamodb_table_backend`: The desired name for the DynamoDB lock table.
*   **For Main Project (`31_AWS_demo_s3_backend/` - Example Infrastructure):**
    *   `aws_region`: The AWS region for deploying the example VPC and EC2 instance (e.g., "us-east-1"). This can be different from `aws_region_backend`.
    *   `az`, `cidr_vpc`, `cidr_subnet1`, `inst_type`, `al2_ssh_key_name`: Variables for configuring the example VPC and EC2 instance.
    *   **Note:** The backend parameters (`bucket`, `key`, `region`, `dynamodb_table`) in the main project's `02_provider.tf` are **hardcoded** in this example. Ensure they align with the actual names and region of the resources created by the `00_PREREQ/` configuration.

## Usage Instructions

### Step 1: Provision Backend Resources

1.  Navigate to the prerequisite configuration directory:
    ```bash
    cd 00_PREREQ/
    ```
2.  Initialize Terraform for this configuration:
    ```bash
    terraform init
    ```
3.  (Optional) Plan the changes:
    ```bash
    terraform plan
    ```
4.  Apply the configuration to create the S3 bucket and DynamoDB table:
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. Verify in the AWS console that the S3 bucket (with versioning and encryption) and the DynamoDB table (with `LockID` as the hash key) are created in the specified `aws_region_backend`.

### Step 2: Deploy Main Project Using the Backend

1.  Navigate to the main project directory (root of `31_AWS_demo_s3_backend/`):
    ```bash
    cd .. 
    # Or navigate directly to 31_AWS_demo_s3_backend/ from your clone root
    ```
2.  Initialize Terraform. It will detect the `backend "s3"` block and configure itself to use the (hardcoded) S3 bucket and DynamoDB table.
    ```bash
    terraform init
    ```
    Terraform will connect to the backend and might ask to copy existing local state if any is found.
3.  (Optional) Plan the changes for the example infrastructure:
    ```bash
    terraform plan
    ```
    Terraform will now read state (if any) from S3 and acquire a lock via DynamoDB.
4.  Apply the configuration to provision the example VPC and EC2 instance:
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. Terraform will acquire a lock, apply changes, and then write the updated state to the S3 bucket, releasing the lock.

If you try to run `terraform apply` from two different terminals simultaneously on the main project after `init`, you should see one of them waiting for the state lock to be released by the other. This demonstrates the DynamoDB locking mechanism.
