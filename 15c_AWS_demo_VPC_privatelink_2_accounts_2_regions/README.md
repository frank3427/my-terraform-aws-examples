# AWS PrivateLink Demonstration: Cross-Account, Cross-Region

## Overview

This Terraform project demonstrates a sophisticated AWS PrivateLink setup, enabling private and secure connectivity between a **Service Provider VPC in AWS Account 1, Region 1** and a **Service Consumer VPC in AWS Account 2, Region 2**. This configuration allows services hosted in Account 1 / Region 1 to be accessed privately by resources in Account 2 / Region 2, without traversing the public internet, using VPC peering, or Transit Gateway. The traffic flows securely over the AWS global backbone.

Key aspects of this setup:
1.  **Cross-Account Authorization:** The VPC Endpoint Service in Account 1 explicitly allows connections from an IAM principal in Account 2.
2.  **Cross-Region Connectivity:** The VPC Interface Endpoint in Account 2 / Region 2 connects to the service offered in Account 1 / Region 1.
3.  **Separate AWS Providers:** Terraform uses distinct AWS provider configurations for each account and its respective region.

## Provider Configuration (`02_provider.tf`)

Terraform manages resources in both AWS accounts and regions by defining two distinct AWS providers. Each provider is configured with a specific AWS CLI profile and its designated AWS region:

*   **Provider for Account 1 (Service Provider in Region 1):**
    ```terraform
    provider "aws" {
      alias   = "acct1"
      region  = var.acct1_region # e.g., "us-east-1"
      profile = var.acct1_profile # AWS CLI profile for Account 1
    }
    ```
*   **Provider for Account 2 (Service Consumer in Region 2):**
    ```terraform
    provider "aws" {
      alias   = "acct2"
      region  = var.acct2_region # e.g., "eu-west-1" (Different from Account 1's region)
      profile = var.acct2_profile # AWS CLI profile for Account 2
    }
    ```
Resources for the Service Provider VPC will use `provider = aws.acct1`, and resources for the Service Consumer VPC will use `provider = aws.acct2`.

## Service Provider VPC (Account 1 in `var.acct1_region`) Details

This VPC, managed by Account 1 and located in `var.acct1_region`, hosts the service.

*   **Network Configuration:**
    *   One public subnet (for Bastion Host and NLB) and one private subnet (for web servers).
    *   Includes an Internet Gateway (IGW) and a NAT Gateway.
*   **Application Servers:**
    *   Two EC2 instances acting as web servers in the private subnet.
*   **Network Load Balancer (NLB):**
    *   Deployed in the public subnet of Account 1. Listens on TCP port 80, forwarding to web servers.
*   **Bastion Host (Account 1):**
    *   An EC2 instance in the public subnet of Account 1.
*   **VPC Endpoint Service (`aws_vpc_endpoint_service.demo15c_pvd`):**
    *   Associated with the NLB in Account 1 / Region 1.
    *   `acceptance_required = false`: For automated acceptance from allowed principals.
    *   `allowed_principals = [local.acct2_role_arn]`: Whitelists an IAM Role ARN from Account 2, granting it permission to connect. (Note: The actual `aws_vpc_endpoint_service` resource does not have a `supported_regions` argument; cross-region availability is inherent to the service name's global uniqueness and AWS backbone routing).

## Service Consumer VPC (Account 2 in `var.acct2_region`) Details

This VPC, managed by Account 2 and located in `var.acct2_region`, consumes the service.

*   **Network Configuration:**
    *   A single public subnet with an IGW.
*   **Bastion Host (Account 2):**
    *   An EC2 instance in the public subnet of Account 2 for testing.
*   **VPC Interface Endpoint (`aws_vpc_endpoint.demo15c_acct2_csm`):**
    *   **Type:** "Interface". Creates Elastic Network Interfaces (ENIs) in the consumer's public subnet in `var.acct2_region`.
    *   **Service Connection:** Connects to the `service_name` of the provider's VPC Endpoint Service in Account 1 / Region 1. The `service_name` is globally unique and inherently includes the region of the service provider.
    *   (Note: The `aws_vpc_endpoint` resource does not have a `service_region` argument; the service's region is part of its unique service name).
    *   `private_dns_enabled = false`: Service is accessed via the endpoint's specific DNS names.

## Cross-Account and Cross-Region PrivateLink

AWS PrivateLink enables this connectivity:
*   The **`service_name`** for the VPC Endpoint Service in Account 1 / Region 1 is globally unique.
*   The Service Consumer VPC in Account 2 / Region 2 creates a VPC Interface Endpoint by referencing this globally unique `service_name`.
*   AWS transparently routes traffic from the ENIs of the consumer's endpoint (in Region 2) over the AWS global backbone to the Network Load Balancer fronting the service in Account 1 / Region 1.
*   The connection is private and secure, without exposing traffic to the public internet.

**Eventual Consistency Workaround:**
A `null_resource` named `wait_for_endpoint_service` with a `local-exec` provisioner that runs `sleep 20` is included in this project.
*   **Purpose:** This introduces a delay. When dealing with cross-account and cross-region resources, particularly VPC Endpoint Services, there can be a brief period of eventual consistency before the service name is fully propagated and resolvable by the consumer account/region attempting to create an endpoint to it. This explicit delay helps mitigate potential "service not found" errors during `terraform apply` if the consumer endpoint creation is attempted too quickly after the provider service is created.

## Key Configuration Variables

Refer to `01_variables.tf` for a complete list. Key variables include:

*   `acct1_profile`: AWS CLI profile name for Account 1.
*   `acct1_region`: AWS region for Account 1's resources (e.g., "us-east-1").
*   `acct2_profile`: AWS CLI profile name for Account 2.
*   `acct2_region`: AWS region for Account 2's resources (e.g., "eu-west-1").
*   `acct2_role_arn_for_pvd_service_principal`: The ARN of the IAM role in Account 2 whitelisted by Account 1's endpoint service.
*   CIDR blocks for provider and consumer VPCs and subnets.
*   `authorized_ips`: Your public IP for SSH access.
*   AMI IDs and instance types for both regions.
*   SSH key names (ensure they exist in the respective accounts and regions).

## Prerequisites

1.  **AWS CLI Profiles:** Configured AWS CLI profiles for Account 1 and Account 2.
2.  **IAM Role in Account 2:** The IAM Role specified by `var.acct2_role_arn_for_pvd_service_principal` must exist in Account 2.
3.  **Permissions:** Ensure both profiles have adequate permissions to create all defined resources in their respective accounts and regions.

## Usage Instructions

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    Review the resources that Terraform will create in both accounts and regions.
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    Provision the AWS resources.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Testing the Setup

1.  **SSH into the Consumer Bastion Host (Account 2, Region 2):**
    *   Obtain the public IP of the bastion instance in Account 2's VPC (`demo15c_acct2_csm_bastion`) from Terraform outputs or the AWS EC2 console (logged into Account 2, in Region 2).
    *   Use your SSH key for Account 2 / Region 2:
        ```bash
        ssh -i /path/to/your/account2-region2-ssh-key.pem ec2-user@<Consumer_Bastion_Account2_Public_IP>
        ```

2.  **Access the Service via the VPC Interface Endpoint:**
    *   The VPC Interface Endpoint in Account 2 / Region 2 will have DNS names.
    *   From the consumer bastion host's command line, use `curl` to one of these DNS names:
        ```bash
        # Example: Using one of the endpoint's specific DNS names
        curl http://<DNS_Name_of_VPC_Interface_Endpoint_ENI_in_Account2_Region2>
        ```
    *   You should receive a response from one of the web servers in the Service Provider VPC (Account 1, Region 1), demonstrating successful cross-account and cross-region private connectivity.

This test confirms that the EC2 instance in Account 2 / Region 2 can privately access the service hosted in Account 1 / Region 1.
