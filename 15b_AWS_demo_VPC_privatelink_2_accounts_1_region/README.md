# AWS PrivateLink Demonstration: Cross-Account, Single Region

## Overview

This Terraform project demonstrates AWS PrivateLink connectivity between a **Service Provider VPC in AWS Account 1** and a **Service Consumer VPC in AWS Account 2**, with both VPCs located within the **same AWS region**. This setup enables private and secure access to services hosted in Account 1 from Account 2, without traversing the public internet, using VPC peering, or Transit Gateway.

The key to this cross-account setup lies in:
1.  Configuring the VPC Endpoint Service in Account 1 to explicitly allow connections from specific IAM principals in Account 2.
2.  Using separate AWS CLI profiles (and thus separate AWS provider configurations in Terraform) for authenticating and managing resources in Account 1 and Account 2.

The architecture is conceptually similar to a single-account PrivateLink setup, but with added cross-account authorization.

## Provider Configuration (`02_provider.tf`)

Terraform manages resources in both AWS accounts by defining two distinct AWS providers. Both providers are configured for the **same AWS region**, but use different AWS CLI profiles for authentication:

*   **Provider for Account 1 (Service Provider):**
    ```terraform
    provider "aws" {
      alias   = "acct1"
      region  = var.aws_region # e.g., "us-east-1"
      profile = var.acct1_profile # AWS CLI profile for Account 1
    }
    ```
*   **Provider for Account 2 (Service Consumer):**
    ```terraform
    provider "aws" {
      alias   = "acct2"
      region  = var.aws_region # Same region as Account 1
      profile = var.acct2_profile # AWS CLI profile for Account 2
    }
    ```
All resources for the Service Provider VPC will use `provider = aws.acct1`, and all resources for the Service Consumer VPC will use `provider = aws.acct2`.

## Service Provider VPC (Account 1 - `acct1_pvd_`) Details

This VPC, managed by Account 1, hosts the service that will be exposed via PrivateLink.

*   **Network Configuration:**
    *   One **public subnet**: Hosts the Bastion Host and the Network Load Balancer (NLB).
    *   One **private subnet**: Hosts the backend web server EC2 instances.
    *   Includes an **Internet Gateway (IGW)** and a **NAT Gateway**.
*   **Application Servers:**
    *   Two **EC2 instances** acting as web servers in the private subnet, serving content on port 80.
*   **Network Load Balancer (NLB):**
    *   Deployed in the public subnet of Account 1.
    *   Listens on TCP port 80 and forwards traffic to the web servers.
*   **Bastion Host (Account 1):**
    *   An **EC2 instance** in the public subnet of Account 1 for administrative access.
*   **VPC Endpoint Service (`aws_vpc_endpoint_service.demo15b_pvd`):**
    *   Associated with the Network Load Balancer in Account 1.
    *   **`acceptance_required = false`**: For this demo, connection requests are automatically accepted if the principal is allowed.
    *   **`allowed_principals = [local.acct2_role_arn]`**: This is a critical setting for cross-account access. It explicitly whitelists an IAM Role ARN from Account 2 (defined in `local.acct2_role_arn`), granting it permission to create an endpoint to this service.

## Service Consumer VPC (Account 2 - `acct2_csm_`) Details

This VPC, managed by Account 2, consumes the service exposed by Account 1.

*   **Network Configuration:**
    *   A single **public subnet** with an **Internet Gateway (IGW)**.
*   **Bastion Host (Account 2):**
    *   An **EC2 instance** in the public subnet of Account 2, used for testing connectivity to the provider's service.
*   **VPC Interface Endpoint (`aws_vpc_endpoint.demo15b_acct2_csm`):**
    *   **Type:** "Interface", creating ENIs in the consumer's public subnet.
    *   **Service Connection:** Connects to the `service_name` of the provider's VPC Endpoint Service in Account 1.
    *   **Security Group:** Associated with its own security group, configured to allow HTTP traffic from the consumer bastion.
    *   **`private_dns_enabled = true`**: This allows the consumer VPC to resolve the service's original private DNS name (if configured and supported by the service) to the PrivateLink endpoint IPs. For generic services like this demo, accessing via the endpoint's specific DNS names is common.

## Cross-Account Authorization

The secure connection between the two accounts is primarily established by the **`allowed_principals`** argument in the `aws_vpc_endpoint_service` resource within Account 1. By specifying an IAM role ARN from Account 2, Account 1 explicitly grants Account 2 (via that role) the permission to establish a connection to its service.

Without this explicit permission, Account 2 would not be able to create an endpoint to the service in Account 1.

## Key Configuration Variables

Refer to `01_variables.tf` for a complete list. Key variables include:

*   `aws_region`: The AWS region for deploying both VPCs (must be the same).
*   `acct1_profile`: AWS CLI profile name for Account 1 (Service Provider).
*   `acct2_profile`: AWS CLI profile name for Account 2 (Service Consumer).
*   `acct2_role_arn_for_pvd_service_principal`: The ARN of the IAM role in Account 2 that Account 1's endpoint service will allow.
*   CIDR blocks for provider and consumer VPCs and subnets.
*   `authorized_ips`: Your public IP for SSH access.
*   AMI IDs and instance types.
*   SSH key names (ensure they exist in the respective accounts and regions).

## Prerequisites

1.  **AWS CLI Profiles:** You must have two AWS CLI profiles configured locally, one for Account 1 and one for Account 2, with necessary permissions to create the resources defined in the Terraform configuration. The names of these profiles should match `var.acct1_profile` and `var.acct2_profile`.
2.  **IAM Role in Account 2:** The IAM Role specified by `var.acct2_role_arn_for_pvd_service_principal` must exist in Account 2. This role doesn't necessarily need extensive permissions itself for the connection to be *allowed* by Account 1; its ARN is used as an identifier. However, the entity *using* Account 2's AWS provider to create the endpoint will need `ec2:CreateVpcEndpoint` permissions in Account 2.

## Usage Instructions

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    Review the resources that Terraform will create in both accounts.
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    Provision the AWS resources across both accounts.
    ```bash
    terraform apply
    ```
    You will be prompted to confirm. Type `yes` to proceed.

## Testing the Setup

1.  **SSH into the Consumer Bastion Host (Account 2):**
    *   Obtain the public IP address of the bastion instance in Account 2's VPC (`demo15b_acct2_csm_bastion`) from Terraform outputs or the AWS EC2 console (logged into Account 2).
    *   Use your SSH key for Account 2:
        ```bash
        ssh -i /path/to/your/account2-ssh-key.pem ec2-user@<Consumer_Bastion_Account2_Public_IP>
        ```

2.  **Access the Service via the VPC Interface Endpoint:**
    *   The VPC Interface Endpoint in Account 2 will have DNS names. Since `private_dns_enabled = true`, if the service had a private DNS name configured and you were resolving from within Account 2's VPC, that might work. However, for direct testing, use the endpoint-specific DNS names.
    *   These DNS names are available in the Terraform output for `aws_vpc_endpoint.demo15b_acct2_csm.dns_entry` or in the AWS VPC console (logged into Account 2) under "Endpoints".
    *   From the consumer bastion host's command line (in Account 2), use `curl` to one of these DNS names:
        ```bash
        # Example: Using one of the endpoint's specific DNS names
        curl http://<DNS_Name_of_VPC_Interface_Endpoint_ENI_in_Account2>
        ```
    *   You should receive a response from one of the web servers in the Service Provider VPC (Account 1), demonstrating successful cross-account private connectivity via AWS PrivateLink.

This test confirms that the EC2 instance in Account 2 can privately access the service hosted in Account 1.I have updated the `README.md` file for the `15b_AWS_demo_VPC_privatelink_2_accounts_1_region/` directory by overwriting it with the new, detailed content.

The updated README now includes:

-   **Overview**: Explains the cross-account PrivateLink setup within a single AWS region and mentions the use of separate AWS CLI profiles for authenticating to Account 1 (provider) and Account 2 (consumer).
-   **Provider Configuration (`02_provider.tf`)**: Details the definition of two AWS providers (`aws.acct1`, `aws.acct2`) using different profiles but targeting the same AWS region.
-   **Service Provider VPC (Account 1 - `acct1_pvd_`) Details**:
    -   Describes the VPC, NLB, web servers, and bastion host in Account 1.
    -   Highlights the **VPC Endpoint Service (`aws_vpc_endpoint_service.demo15b_pvd`)** and its key configuration: `allowed_principals = [local.acct2_role_arn]` to explicitly whitelist an IAM principal from Account 2, and `acceptance_required = false`.
-   **Service Consumer VPC (Account 2 - `acct2_csm_`) Details**:
    -   Describes the VPC, bastion host, and VPC endpoint in Account 2.
    -   Details the **VPC Interface Endpoint (`aws_vpc_endpoint.demo15b_acct2_csm`)** connecting to the service in Account 1 and notes `private_dns_enabled = true`.
-   **Cross-Account Authorization**: Emphasizes the role of `allowed_principals` in enabling secure cross-account connectivity.
-   **Key Configuration Variables**: Mentions important variables like `aws_region`, `acct1_profile`, `acct2_profile`, and `acct2_role_arn_for_pvd_service_principal`.
-   **Prerequisites**: States the need for configured AWS CLI profiles for both accounts and the existence of the IAM role in Account 2 specified in `allowed_principals`.
-   **Usage Instructions**: Standard Terraform `init`, `plan`, `apply` commands.
-   **Testing the Setup**: Guides users on how to SSH into the consumer bastion host in Account 2 and use `curl` with the VPC Interface Endpoint's DNS names to test connectivity to the provider's service in Account 1.

The inaccuracy regarding different regions in the old README's summary has been corrected, and the new content consistently refers to a single-region setup. The README is now more comprehensive and accurately describes the cross-account PrivateLink demonstration.
